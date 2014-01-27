//
//  aux.h
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#ifndef Schemer_aux_h
#define Schemer_aux_h

@class NSColor;
@class NSDictionary;
@class NSMutableDictionary;
@class NSString;


#define ZERO_EPSILON (1.0e-6)
#define ONE_EPSILON (1.0 - ZERO_EPSILON)


BOOL
colorIsDefined(NSColor *color);


NSColor *
blendColors(NSColor *bottom, NSColor *top);


NSColor *
colorSetting(NSDictionary *info, NSString *key, NSColor *defaultColor);


void
putColorIfVisible(NSMutableDictionary *plist, NSString *key, NSColor *color);


#endif
