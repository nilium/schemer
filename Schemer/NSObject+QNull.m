//
//  NSObject+QNull.m
//  Schemer
//
//  Created by Noel Cower on 01/27/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "NSObject+QNull.h"

@implementation NSObject (QNull)

@dynamic isNull;
@dynamic selfIfNotNull;


- (BOOL)isNull
{
  return [self isKindOfClass:[NSNull class]] || self == NSNull.null;
}


- (id)selfIfNotNull
{
  return !([self isKindOfClass:[NSNull class]] || self == NSNull.null) ? self : nil;
}

@end
