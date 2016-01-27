//
//  ZMKeyedArchiver.h
//  归档/解档
//
//  Created by joemo on 15/2/27.
//  Copyright (c) 2015年 joemo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZMKeyedArchiver : NSKeyedArchiver
/**
 *  归档
 */
+ (BOOL)archiveRootObject:(id)rootObject subObjects:(NSArray *)subObjects toFile:(NSString *)path;

@end

@interface ZMKeyedUnarchiver : NSKeyedUnarchiver
/**
 *  解档
 */
+ (id)unarchiveObjectWithFile:(NSString *)path rootObjcClass:(Class)rootObjcClass subObjcClasses:(NSArray *)subObjcClasses;

@end
