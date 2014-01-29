//
//  QAppDelegate.m
//  Schemer
//
//  Created by Noel Cower on 01/28/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "QAppDelegate.h"


NSString *const QFontChangeNotification = @"QUserFontChangedNotification";


@implementation QAppDelegate {
  NSFont *_font;
}


- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
  _font = [NSFont userFixedPitchFontOfSize:0.0];
  NSFontManager *manager = [NSFontManager sharedFontManager];
  [manager setSelectedFont:_font isMultiple:NO];
  manager.delegate = self;
}


- (void)changeFont:(id)sender
{
  _font = [sender convertFont:_font];
  [NSFont setUserFixedPitchFont:_font];
  [[NSNotificationCenter defaultCenter]
   postNotificationName:QFontChangeNotification object:self];
}

@end
