//
//  MonsterPartsFactory.h
//  BranchMonsterFactory
//
//  Created by Alex Austin on 9/6/14.
//  Copyright (c) 2014 Branch, Inc All rights reserved.
//

@import AppKit;

@interface MonsterPartsFactory : NSObject

+ (NSColor *)colorForIndex:(NSInteger)index;
+ (NSImage *)imageForBody:(NSInteger)index;
+ (NSImage *)imageForFace:(NSInteger)index;
+ (NSString *)descriptionForIndex:(NSInteger)index;
+ (NSInteger)sizeOfBodyArray;
+ (NSInteger)sizeOfFaceArray;

@end
