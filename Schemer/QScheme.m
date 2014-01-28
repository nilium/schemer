//
//  QScheme.m
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "QScheme.h"
#import "QSchemeRule.h"
#import "NSFilters.h"
#import "NSColor+QHexColor.h"
#import "aux.h"


static
BOOL
isBaseRuleDictionary(NSDictionary *rule)
{
  return 1 == [rule count] && nil != rule[@"settings"];
}


static
NSDictionary *
getBaseRuleDictionary(NSArray *settings)
{
  for (id value in settings) {
    if (![value isKindOfClass:[NSDictionary class]]) {
      continue;
    }

    if (isBaseRuleDictionary(value)) {
      return value;
    }
  }
  return nil;
}


static
NSArray *
getRulesDictionaries(NSArray *settings)
{
  return [settings rejectedArrayUsingBlock:^BOOL(id obj) {
    return ![obj isKindOfClass:[NSDictionary class]] || isBaseRuleDictionary(obj);
  }];
}


@interface QScheme ()

@property (copy, readwrite) NSUUID *uuid;

- (void)notifyDocumentChange;

@end


@implementation QScheme {
  __weak NSDocument *_document;
}


- (id)init
{
  if ((self = [super init])) {
    NSColor *black = [NSColor.blackColor forScheme];
    self.foregroundColor = black;
    self.backgroundColor = [NSColor.whiteColor forScheme];
    self.lineHighlightColor = [NSColor colorWithWhite:0.0f alpha:0.07f];
    self.selectionColor = [[NSColor selectedTextBackgroundColor] forScheme];
    self.selectionBorderColor = [self.selectionColor colorWithAlphaComponent:0.0f];
    self.inactiveSelectionColor = [self.selectionColor colorWithAlphaComponent:0.5f];
    self.invisiblesColor = [[NSColor colorWithWhite:0.75f alpha:1.0f] forScheme];
    self.caretColor = black;
    self.uuid = [NSUUID UUID];

    self.rules = @[];
  }
  return self;
}


- (id)initWithDocument:(NSDocument *)doc
{
  if ((self = [self init])) {
    _document = doc;
  }
  return self;
}


- (id)initWithPropertyList:(NSDictionary *)plist document:(NSDocument *)doc
{
  if ((self = [self initWithDocument:doc])) {
    NSDictionary *baseRules = getBaseRuleDictionary(plist[@"settings"]);
    NSArray *rules = getRulesDictionaries(plist[@"settings"]);

    if (!baseRules || !baseRules[@"settings"]) {
      return nil;
    }

    NSDictionary *settings      = baseRules[@"settings"];
    self.foregroundColor        = [colorSetting(settings, @"foreground", self.foregroundColor) colorWithAlphaComponent:1.0];
    self.backgroundColor        = [colorSetting(settings, @"background", self.backgroundColor) colorWithAlphaComponent:1.0];
    self.lineHighlightColor     = colorSetting(settings, @"lineHighlight", self.lineHighlightColor);
    self.selectionColor         = colorSetting(settings, @"selection", self.selectionColor);
    self.selectionBorderColor   = colorSetting(settings, @"selectionBorder", self.selectionBorderColor);
    self.inactiveSelectionColor = colorSetting(settings, @"inactiveSelection", self.inactiveSelectionColor);
    self.invisiblesColor        = colorSetting(settings, @"invisibles", self.invisiblesColor);
    self.caretColor             = colorSetting(settings, @"caret", self.caretColor);

    self.rules = [rules mappedArrayUsingBlock:^id(id obj) {
      return [[QSchemeRule alloc] initWithPropertyList:obj document:doc];
    }];

    self.uuid =
      baseRules[@"uuid"]
      ? [[NSUUID alloc] initWithUUIDString:baseRules[@"uuid"]]
      : [NSUUID UUID];
  }
  return self;
}


- (id)copyWithZone:(NSZone *)zone
{
  QScheme *scheme = [[[self class] alloc] initWithDocument:_document];
  if (scheme) {
    scheme.uuid = self.uuid;

    scheme.foregroundColor        = self.foregroundColor;
    scheme.backgroundColor        = self.backgroundColor;
    scheme.lineHighlightColor     = self.lineHighlightColor;
    scheme.selectionColor         = self.selectionColor;
    scheme.selectionBorderColor   = self.selectionBorderColor;
    scheme.inactiveSelectionColor = self.inactiveSelectionColor;
    scheme.invisiblesColor        = self.invisiblesColor;
    scheme.caretColor             = self.caretColor;

    scheme.rules = [self.rules mappedArrayUsingBlock:^id(id obj) { return [obj copy]; }];
  }
  return scheme;
}


- (NSDictionary *)toPropertyList
{
  NSMutableDictionary *plist = [NSMutableDictionary new];

  plist[@"uuid"] = self.uuid.UUIDString;

  NSMutableArray *baseRules = [NSMutableArray arrayWithCapacity:[self.rules count] + 1];

  NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:8];

  settings[@"foreground"] = [self.foregroundColor toHexColorString];
  settings[@"background"] = [[self.backgroundColor colorWithAlphaComponent:1.0] toHexColorString];

  putColorIfVisible(settings, @"lineHighlight", self.lineHighlightColor);
  putColorIfVisible(settings, @"selection", self.selectionColor);
  putColorIfVisible(settings, @"selectionBorder", self.selectionBorderColor);
  putColorIfVisible(settings, @"inactiveSelection", self.inactiveSelectionColor);
  putColorIfVisible(settings, @"invisibles", self.invisiblesColor);
  putColorIfVisible(settings, @"caret", self.caretColor);

  [baseRules addObject:@{ @"settings": settings }];

  for (QSchemeRule *rule in self.rules) {
    [baseRules addObject:[rule toPropertyList]];
  }

  plist[@"settings"] = baseRules;

  return plist;
}


- (void)notifyDocumentChange
{
  __weak NSDocument *doc = _document;
  dispatch_async(dispatch_get_main_queue(), ^{
    if (doc) {
      [doc updateChangeCount:NSChangeDone];
    }
  });
}


- (void)didChange:(NSKeyValueChange)changeKind valuesAtIndexes:(NSIndexSet *)indexes forKey:(NSString *)key
{
  [self notifyDocumentChange];
  [super didChange:changeKind valuesAtIndexes:indexes forKey:key];
}


- (void)didChangeValueForKey:(NSString *)key
{
  [self notifyDocumentChange];
  [super didChangeValueForKey:key];
}


-(void)didChangeValueForKey:(NSString *)key withSetMutation:(NSKeyValueSetMutationKind)mutationKind usingObjects:(NSSet *)objects
{
  [self notifyDocumentChange];
  [super didChangeValueForKey:key withSetMutation:mutationKind usingObjects:objects];
}

@end
