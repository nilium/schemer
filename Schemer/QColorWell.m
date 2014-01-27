//
//  QColorWell.m
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "QColorWell.h"

@implementation QColorWell

- (void)activate:(BOOL)exclusive
{
  [NSColorPanel sharedColorPanel].showsAlpha = YES;
  [super activate:exclusive];
}

@end
