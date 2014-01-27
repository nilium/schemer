//
//  NSObject+QNull.h
//  Schemer
//
//  Created by Noel Cower on 01/27/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (QNull)

@property (readonly) BOOL isNull;
@property (readonly) id selfIfNotNull;

@end
