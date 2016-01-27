//
//  ZMKeyedArchiver.m
//  归档/解档
//
//  Created by joemo on 15/2/27.
//  Copyright (c) 2015年 joemo. All rights reserved.
//

#import "ZMKeyedArchiver.h"
#import <objc/runtime.h>

const static char *ProtocolName = "NSCoding";

#pragma mark - 归档
@implementation ZMKeyedArchiver
// 归档
+ (BOOL)archiveRootObject:(id)rootObject subObjects:(NSArray *)subObjcClasses toFile:(NSString *)path{
    if (subObjcClasses.count == 0) {
        if (class_conformsToProtocol([rootObject class], objc_getProtocol(ProtocolName)) && class_respondsToSelector([rootObject class], @selector(encodeWithCoder:))) {
            return [super archiveRootObject:rootObject toFile:path];
        }else{
            if (class_conformsToProtocol([rootObject class], objc_getProtocol(ProtocolName))) {
                [self addMethodAndImplementationToClass:[rootObject class] withSel:@selector(encodeWithCoder:)];
                return [super archiveRootObject:rootObject toFile:path];
            }else{
                class_addProtocol([rootObject class], objc_getProtocol(ProtocolName));
                [self addMethodAndImplementationToClass:[rootObject class] withSel:@selector(encodeWithCoder:)];
                return [super archiveRootObject:rootObject toFile:path];
            }
            return NO;
        }
    }else{
        NSMutableArray *arrM = [NSMutableArray array];
        [arrM addObject:[rootObject class]];
        [arrM addObjectsFromArray:subObjcClasses];
        NSArray *objcClasses = [arrM copy];
        
        [objcClasses enumerateObjectsUsingBlock:^(Class objcClass, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!class_conformsToProtocol(objcClass, objc_getProtocol(ProtocolName))) {
                class_addProtocol(objcClass, objc_getProtocol(ProtocolName));
            }
            if (!class_respondsToSelector(objcClass, @selector(encodeWithCoder:))) {
                [self addMethodAndImplementationToClass:objcClass withSel:@selector(encodeWithCoder:)];
            }
        }];
        return [super archiveRootObject:rootObject toFile:path];
    }
}

// 检查文件是否存在
+ (BOOL)checkFileWithPath:(NSString *)filePath{
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath] ? YES : NO;
}

// 给目标类添加encodeWithCoder方法
+ (void)addMethodAndImplementationToClass:(Class)targetClass withSel:(SEL)sel{
    IMP codeImp = class_getMethodImplementation([ZMKeyedArchiver class], sel);
    class_addMethod([targetClass class], sel, codeImp, "@");
}

// encodeWithCoder方法实现
- (void)encodeWithCoder:(NSCoder *)aCoder{
    unsigned int outCount = 0;
    Ivar *ivars = class_copyIvarList([self class], &outCount);
    for (int i = 0; i < outCount; i++) {
        Ivar var = *(ivars + i);
        const char *proName = ivar_getName(var);
        NSString *key = [NSString stringWithUTF8String:proName];
        id value = [self valueForKey:key];
        [aCoder encodeObject:value forKey:key];
    }
    free(ivars);
}

@end

#pragma mark - 解档
@implementation ZMKeyedUnarchiver

+ (id)unarchiveObjectWithFile:(NSString *)path rootObjcClass:(Class)rootObjcClass subObjcClasses:(NSArray *)subObjcClasses{
    if (subObjcClasses.count == 0) {
        if (class_conformsToProtocol(rootObjcClass, objc_getProtocol(ProtocolName)) && class_respondsToSelector(rootObjcClass, @selector(initWithCoder:))) {
            return [super unarchiveObjectWithFile:path];
        }else{
            if (class_conformsToProtocol(rootObjcClass, objc_getProtocol(ProtocolName))) {
                [self addMethodAndImplementationToClass:[rootObjcClass class] withSel:@selector(initWithCoder:)];
                return [super unarchiveObjectWithFile:path];
            }else{
                class_addProtocol(rootObjcClass, objc_getProtocol(ProtocolName));
                [self addMethodAndImplementationToClass:[rootObjcClass class] withSel:@selector(initWithCoder:)];
                return [super unarchiveObjectWithFile:path];
            }
            return nil;
        }
    }else{
        NSMutableArray *arrM = [NSMutableArray array];
        [arrM addObject:rootObjcClass];
        [arrM addObjectsFromArray:subObjcClasses];
        NSArray *objcClasses = [arrM copy];
        
        [objcClasses enumerateObjectsUsingBlock:^(Class objcClass, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!class_conformsToProtocol(objcClass, objc_getProtocol(ProtocolName))) {
                class_addProtocol(objcClass, objc_getProtocol(ProtocolName));
            }
            if (!class_respondsToSelector(objcClass, @selector(initWithCoder:))) {
                [self addMethodAndImplementationToClass:objcClass withSel:@selector(initWithCoder:)];
            }
        }];
        return [super unarchiveObjectWithFile:path];
    }
}

+ (void)addMethodAndImplementationToClass:(Class)targetClass withSel:(SEL)sel{
    IMP decodeImp = class_getMethodImplementation([ZMKeyedUnarchiver class], @selector(initWithCoder:));
    class_addMethod(targetClass, @selector(initWithCoder:), decodeImp, "@");
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [self init]) {
        unsigned int outCount = 0;
        Ivar *ivars = class_copyIvarList([self class], &outCount);
        for (int i = 0; i < outCount; i++) {
            Ivar var = *(ivars + i);
            NSString *key = @(ivar_getName(var));
            id value = [aDecoder decodeObjectForKey:key];
            [self setValue:value forKey:key];
        }
        free(ivars);
    }
    return self;
}

@end
