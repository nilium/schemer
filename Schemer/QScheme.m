/*===========================================================================
  Copyright (c) 2014, Noel Cower.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
===========================================================================*/

/* QScheme.m - Noel Cower */

#import "QScheme.h"
#import "QSchemeRule.h"
#import "NSFilters.h"
#import "NSColor+QHexColor.h"
#import "aux.h"


static
BOOL
isBaseRuleDictionary(NSDictionary *rule);

static
NSDictionary *
getBaseRuleDictionary(NSArray *settings);

static
NSArray *
getRulesDictionaries(NSArray *settings);


static id (^const copyRuleBlock)(id) = ^(id obj) {
  return [obj copy];
};


static id (^const convertPListToRuleBlock)(id) = ^id(id obj) {
  return [[QSchemeRule alloc] initWithPropertyList:obj];
};


static BOOL (^const indexOfBaseRulesDictTest)(id, NSUInteger, BOOL *) =
  ^(id obj, NSUInteger index, BOOL *stop) {
    return isBaseRuleDictionary(obj);
  };


static
BOOL
isBaseRuleDictionary(NSDictionary *rule)
{
  return
       [rule isKindOfClass:[NSDictionary class]]
    && 1 == [rule count]
    && nil != rule[@"settings"];
}


static
NSDictionary *
getBaseRuleDictionary(NSArray *settings)
{
  const NSUInteger index =
    [settings indexOfObjectPassingTest:indexOfBaseRulesDictTest];

  if (index != NSNotFound) {
    return settings[index];
  }

  return nil;
}


static
NSArray *
getRulesDictionaries(NSArray *settings)
{
  return [settings rejectedBy:^BOOL(id obj) {
    return isBaseRuleDictionary(obj);
  }];
}


@interface QScheme ()

@property (copy, readwrite) NSUUID *uuid;

@end


@implementation QScheme

- (id)init
{
  if ((self = [super init])) {
    NSColor *black = [NSColor.blackColor forScheme];
    NSColor *noColor = [[NSColor colorWithWhite:0.0 alpha:0.0] forScheme];

    self.foregroundColor = black;
    self.backgroundColor = [NSColor.whiteColor forScheme];

    self.lineHighlightColor =
      [[NSColor colorWithWhite:0.0f alpha:0.07f] forScheme];

    self.selectionColor =
      [[NSColor selectedTextBackgroundColor] forScheme];
    self.selectionBorderColor =
      [self.selectionColor colorWithAlphaComponent:0.0f];
    self.inactiveSelectionColor =
      [self.selectionColor colorWithAlphaComponent:0.5f];

    self.invisiblesColor =
      [[NSColor colorWithWhite:0.75f alpha:1.0f] forScheme];

    self.caretColor = black;

    self.gutterBGColor = noColor;
    self.gutterFGColor = noColor;

    self.findHiliteBGColor = noColor;
    self.findHiliteFGColor = noColor;

    self.uuid = [NSUUID UUID];
    self.rules = @[];
  }

  return self;
}


- (id)initWithPropertyList:(NSDictionary *)plist
{
  static dispatch_queue_t conversion_queue = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    conversion_queue = dispatch_queue_create(
      "net.spifftastic.schemer.convert",
      DISPATCH_QUEUE_CONCURRENT
      );
  });

  if ((self = [self init])) {
    NSDictionary *baseRules = getBaseRuleDictionary(plist[@"settings"]);
    NSArray *rules = getRulesDictionaries(plist[@"settings"]);

    if (!baseRules || !baseRules[@"settings"]) {
      return nil;
    }

    NSDictionary *settings = baseRules[@"settings"];

    self.foregroundColor =
      [colorSetting(settings, @"foreground", self.foregroundColor)
       colorWithAlphaComponent:1.0];

    self.backgroundColor =
      [colorSetting(settings, @"background", self.backgroundColor)
       colorWithAlphaComponent:1.0];

    self.lineHighlightColor =
      colorSetting(settings, @"lineHighlight", self.lineHighlightColor);

    self.selectionColor =
      colorSetting(settings, @"selection", self.selectionColor);

    self.selectionBorderColor =
      colorSetting(settings, @"selectionBorder", self.selectionBorderColor);

    self.inactiveSelectionColor =
      colorSetting(settings, @"inactiveSelection", self.inactiveSelectionColor);

    self.invisiblesColor =
      colorSetting(settings, @"invisibles", self.invisiblesColor);

    self.caretColor = colorSetting(settings, @"caret", self.caretColor);

    self.gutterFGColor =
      colorSetting(settings, @"gutterForeground", self.gutterFGColor);

    self.gutterBGColor =
      colorSetting(settings, @"gutter", self.gutterBGColor);

    self.findHiliteFGColor =
      colorSetting(settings, @"findHighlightForeground", self.findHiliteFGColor);

    self.findHiliteBGColor =
      colorSetting(settings, @"findHighlight", self.findHiliteBGColor);

    self.rules =
      [rules mappedTo:convertPListToRuleBlock queue:conversion_queue stride:16];

    NSString *uuidString = baseRules[@"uuid"];
    if (uuidString) {
      NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
      if (uuid) {
        self.uuid = uuid;
      } else {
        NSLog(@"%@ is an invalid UUID, generating a new one.", uuidString);
      }
    }
  }

  return self;
}


- (id)initWithScheme:(QScheme *)scheme
{
  if ((self = [self init]) && scheme) {
    self.foregroundColor        = scheme.foregroundColor;
    self.backgroundColor        = scheme.backgroundColor;
    self.lineHighlightColor     = scheme.lineHighlightColor;
    self.selectionColor         = scheme.selectionColor;
    self.selectionBorderColor   = scheme.selectionBorderColor;
    self.inactiveSelectionColor = scheme.inactiveSelectionColor;
    self.invisiblesColor        = scheme.invisiblesColor;
    self.caretColor             = scheme.caretColor;
    self.rules                  = [scheme.rules mappedTo:copyRuleBlock];
    self.uuid                   = scheme.uuid;
  }
  return self;
}


- (id)copyWithZone:(NSZone *)zone
{
  return [[self.class alloc] initWithScheme:self];
}


- (NSDictionary *)toPropertyList
{
  NSMutableDictionary *plist = [NSMutableDictionary new];

  plist[@"uuid"] = self.uuid.UUIDString;

  NSMutableArray *baseRules =
    [NSMutableArray arrayWithCapacity:[self.rules count] + 1];

  NSMutableDictionary *settings =
    [NSMutableDictionary dictionaryWithCapacity:8];

  settings[@"foreground"] = [self.foregroundColor toHexColorString];
  settings[@"background"] =
    [[self.backgroundColor colorWithAlphaComponent:1.0] toHexColorString];

  putColorIfVisible(settings, @"lineHighlight", self.lineHighlightColor);
  putColorIfVisible(settings, @"selection", self.selectionColor);
  putColorIfVisible(settings, @"selectionBorder", self.selectionBorderColor);
  putColorIfVisible(settings, @"inactiveSelection", self.inactiveSelectionColor);
  putColorIfVisible(settings, @"invisibles", self.invisiblesColor);
  putColorIfVisible(settings, @"caret", self.caretColor);
  putColorIfVisible(settings, @"gutterForeground", self.gutterFGColor);
  putColorIfVisible(settings, @"gutter", self.gutterBGColor);
  putColorIfVisible(settings, @"findHighlightForeground", self.findHiliteFGColor);
  putColorIfVisible(settings, @"findHighlight", self.findHiliteBGColor);

  [baseRules addObject:@{ @"settings": settings }];

  for (QSchemeRule *rule in self.rules) {
    [baseRules addObject:[rule toPropertyList]];
  }

  plist[@"settings"] = baseRules;

  return plist;
}

@end
