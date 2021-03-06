//
//  SuperDao.m
//  Meet
//
//  Created by jiahui on 16/5/9.
//  Copyright © 2016年 Meet. All rights reserved.
//


#import "SuperDao.h"
#import "AppData.h"

@interface SuperDao ()

@end
@implementation SuperDao

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.db = [AppData shareInstance].db;
    }
    return self;
}

- (NSString *)tableName
{
    NSAssert(NO, @"SubClass: tableName");
    return nil;
}

- (id)mappingRs2Bean:(FMResultSet *)rs
{
    NSAssert(NO, @"Subclass: mappingRs2Bean");
    return nil;
}

- (FMResultSet *)mappingBean2Rs:(id)bean
{
    NSAssert(NO, @"Subclass: mappingBean2Rs");
    return nil;
}

- (int)selectCount
{
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", self.tableName];
    FMResultSet *rs = [_db executeQuery:sql];
    int totalCount = 0;
    while ([rs next]) {
        totalCount = [rs intForColumnIndex:0];
    }
    [rs close];
    return totalCount;
}

- (int)selectMaxValue:(NSString *)column
{
    NSString *sql = [NSString stringWithFormat:@"SELECT MAX(%@) FROM %@", column, self.tableName];
    FMResultSet *rs = [_db executeQuery:sql];
    int maxValue = 0;
    while ([rs next]) {
        maxValue = [rs intForColumnIndex:0];
    }
    [rs close];
    return maxValue;
}

- (NSArray *)selectAll
{
    return [self selectWithWhere:nil order:nil];
}

- (NSArray *)selectWithWhere:(NSString *)whereSql
{
    return [self selectWithWhere:whereSql order:nil];
}

- (NSArray *)selectWithOrder:(NSString *)orderSql
{
    return [self selectWithWhere:nil order:orderSql];
}

- (NSArray *)selectWithWhere:(NSString *)whereSql order:(NSString *)orderSql
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT * FROM %@", self.tableName];
    if (whereSql) {
        [sql appendFormat:@" WHERE %@", whereSql];
    }
    if (orderSql) {
        [sql appendFormat:@" ORDER BY %@", orderSql];
    }
    
    FMResultSet *rs = [_db executeQuery:sql];
    NSMutableArray *beanArray = [NSMutableArray array];
    while ([rs next]) {
        [beanArray addObject:[self mappingRs2Bean:rs]];
    }
    [rs close];
    if (beanArray.count > 0) {
        return beanArray;
    } else {
        return nil;
    }
}

- (NSArray *)selectWithWhere:(NSString *)whereSql limitScalar:(NSInteger)scalar andStart:(NSInteger)start {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT * FROM %@", self.tableName];
    if (whereSql) {
        [sql appendFormat:@" WHERE %@", whereSql];
    }
    [sql appendFormat:@"LIMIT %ld", (long)scalar];
    if (start) {
        [sql appendFormat:@"OFFSET %ld",(long)start];
    }
    FMResultSet *rs = [_db executeQuery:sql];
    NSMutableArray *beanArray = [NSMutableArray array];
    while ([rs next]) {
        [beanArray addObject:[self mappingRs2Bean:rs]];
    }
    [rs close];
    if (beanArray.count > 0) {
        return beanArray;
    } else {
        return nil;
    }
}

- (BOOL)insertBean:(BaseModel *)bean
{
    NSMutableString *qmarkString = [NSMutableString stringWithString:@"?, "];
    [bean.columnArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [qmarkString appendString:@"?, "];
    }];
    if (qmarkString.length > 2) {
        [qmarkString deleteCharactersInRange:NSMakeRange(qmarkString.length - 2, 2)];
    }
    
    NSMutableString *columnString = [NSMutableString stringWithFormat:@"%@, ",kBeanIdKey];
    [bean.columnArray enumerateObjectsUsingBlock:^(NSString *column, NSUInteger idx, BOOL *stop) {
        [columnString appendFormat:@"%@, ", column];
    }];
    if (columnString.length > 2) {
        [columnString deleteCharactersInRange:NSMakeRange(columnString.length - 2, 2)];
    }
    NSMutableArray *valueArray = [NSMutableArray array];
    NSString *uuid = [self get_uuid];
    [valueArray addObject:uuid];
    [valueArray addObjectsFromArray:bean.valueArray];
    NSMutableString *sql = [NSMutableString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", self.tableName, columnString, qmarkString];
    BOOL insertSuccess = [_db executeUpdate:sql withArgumentsInArray:valueArray];
    if (!insertSuccess) {
        NSLog(@"ERROR: Insert data failed!");
        return NO;
    } else
        return YES;
}

- (NSString *)get_uuid
{
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    CFRelease(uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString*)uuid_string_ref];
    CFRelease(uuid_string_ref);
    return uuid;
}

- (void)deleteAll
{
    [self deleteWithWhere:nil];
}

- (void)deleteWithWhere:(NSString *)whereSql
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@", self.tableName];
    if (whereSql) {
        [sql appendFormat:@" WHERE %@", whereSql];
    }
    [_db executeUpdate:sql];
}

- (BOOL)deleteBeanWithIdKey:(NSString *)idKey
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE %@ = '%@'", self.tableName,kBeanIdKey, idKey];
    
    return [_db executeUpdate:sql];
}

- (BOOL)updateBean:(BaseModel *)bean;
{
    NSMutableString *columnString = [NSMutableString string];
    [bean.columnArray enumerateObjectsUsingBlock:^(NSString *column, NSUInteger idx, BOOL *stop) {
        [columnString appendFormat:@"%@ = ?, ", column];
    }];
    if (columnString.length > 2) {
        [columnString deleteCharactersInRange:NSMakeRange(columnString.length - 2, 2)];
    }
    NSMutableString *sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = '%@'", self.tableName, columnString, kBeanIdKey, bean.idKey];
//    NSLog(@"%@", sql);
//    NSLog(@"%@", bean.valueArray);
    if ([_db open]) {
        BOOL updateSuccess = [_db executeUpdate:sql withArgumentsInArray:bean.valueArray];
        if (!updateSuccess) {
            NSLog(@"ERROR: Update data failed!");
        }
        return updateSuccess;
    }
    return NO;
}


@end
