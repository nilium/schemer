//
//  QColorWellOpaque.m
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "QColorWellOpaque.h"

@implementation QColorWellOpaque

- (void)activate:(BOOL)exclusive
{
  [NSColorPanel sharedColorPanel].showsAlpha = NO;
  [super activate:exclusive];
}

@end
