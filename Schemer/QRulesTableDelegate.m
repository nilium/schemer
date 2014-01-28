//
//  QRulesTableDelegate.m
//  Schemer
//
//  Created by Noel Cower on 01/27/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "QRulesTableDelegate.h"
#import "QScheme.h"
#import "QSchemeRule.h"
#import "aux.h"


static NSDictionary *g_columnIDs = nil;


NSString *const QRuleSelectedNotification = @"QRuleSelectedNotification";
NSString *const QSelectedRules = @"rules";


@interface QRulesTableDelegate ()

@property (weak, readwrite) QSchemeRule *selectedRule;

- (void)bindView:(NSView *)view toRule:(QSchemeRule *)rule forColumn:(int)column;

@end


enum {
  COL_INVALID = 0,
  COL_NAME,
  COL_FOREGROUND,
  COL_BACKGROUND,
  COL_FLAGS
};


@implementation QRulesTableDelegate {
  QScheme *_scheme;
  __weak NSTableView *_tableView;
}


+ (void)initialize
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    g_columnIDs = @{
      @"name": @(COL_NAME),
      @"foreground": @(COL_FOREGROUND),
      @"background": @(COL_BACKGROUND),
      @"flags": @(COL_FLAGS)
    };
  });

  [super initialize];
}


- (id)initWithScheme:(QScheme *)scheme tableView:(NSTableView *)view
{
  if ((self = [self init])) {
    _scheme = scheme;
    _tableView = view;
  }
  return self;
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  NSView *view = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
  [self bindView:view toRule:_scheme.rules[row] forColumn:[g_columnIDs[tableColumn.identifier] intValue]];
  return view;
}


static
NSFont *
convertFontWithOptionalTrait(BOOL flag, NSFontTraitMask trait, NSFont *font, NSFontManager *manager)
{
  if (flag) {
    return [manager convertFont:font toHaveTrait:trait];
  } else {
    return [manager convertFont:font toNotHaveTrait:trait];
  }
}


- (void)bindView:(NSView *)view toRule:(QSchemeRule *)rule forColumn:(int)column
{
  NSColorWell *well = nil;
  switch (column) {
  case COL_NAME: {
    NSTextField *text = (NSTextField *)view;
    NSFont *font = [NSFont userFixedPitchFontOfSize:0.0];
    uint32_t flags = rule.flags.unsignedIntValue;

    NSFontManager *manager = [NSFontManager sharedFontManager];
    font = convertFontWithOptionalTrait(flags & QBoldFlag, NSBoldFontMask, font, manager);
    font = convertFontWithOptionalTrait(flags & QItalicFlag, NSItalicFontMask, font, manager);

    text.font = font;
    text.textColor = colorIsDefined(rule.foreground) ? rule.foreground : _scheme.foregroundColor;
    text.backgroundColor =
      colorIsDefined(rule.background)
      ? blendColors(_scheme.backgroundColor, rule.background)
      : [_scheme.backgroundColor colorWithAlphaComponent:0.75];

    if (flags & QUnderlineFlag) {
      NSAttributedString *name =
      	[[NSAttributedString alloc]
         initWithString:rule.name
         attributes:@{ NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle) }];
      text.attributedStringValue = name;
    } else {
      text.stringValue = rule.name;
    }
  } break;

  case COL_FOREGROUND: {
    well = (NSColorWell *)view;
    [well setColor:rule.foreground];
    well.target = self;
    well.action = @selector(updateForegroundRuleColor:);
  } break;

  case COL_BACKGROUND: {
    well = (NSColorWell *)view;
    [well setColor:rule.background];
    well.target = self;
    well.action = @selector(updateBackgroundRuleColor:);
  } break;

  case COL_FLAGS: {
    NSSegmentedControl *seg = (NSSegmentedControl *)view;
    uint32_t flags = rule.flags.unsignedIntValue;
    [seg setSelected:(flags & QBoldFlag) forSegment:0];
    [seg setSelected:(flags & QItalicFlag) forSegment:1];
    [seg setSelected:(flags & QUnderlineFlag) forSegment:2];
    [seg setTarget:self];
    [seg setAction:@selector(updateRuleFlags:)];
  } break;

  default:
    @throw [NSException
            exceptionWithName:@"InvalidColumnID"
            reason:@"Invalid column ID when binding view"
            userInfo:nil];
    break;
  }
}


- (void)updateRuleFlags:(NSSegmentedControl *)sender
{
}


- (void)updateBackgroundRuleColor:(NSColorWell *)well
{
  if (!_tableView) {
    return;
  }

  NSInteger row = [_tableView rowForView:well];
  if (row < 0) {
    return;
  }

  QSchemeRule *rule = _scheme.rules[row];
  rule.background = well.color;
  [rule didChangeValueForKey:@"background"];

  [self updateRuleLabelAtRow:row];
}


- (void)updateForegroundRuleColor:(NSColorWell *)well
{
  if (!_tableView) {
    return;
  }

  NSInteger row = [_tableView rowForView:well];
  if (row < 0) {
    return;
  }

  QSchemeRule *rule = _scheme.rules[row];
  rule.foreground = well.color;
  [rule didChangeValueForKey:@"foreground"];

  [self updateRuleLabelAtRow:row];
}


- (void)updateRuleLabelAtRow:(NSInteger)row
{
  NSTableColumn *nameCol = [_tableView tableColumnWithIdentifier:@"name"];
  NSInteger column = [_tableView.tableColumns indexOfObject:nameCol];
  if (column >= 0) {
    [_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:column]];
  }
}


- (void)doubleClickedTableView:(NSTableView *)tableView
{
  NSTableColumn *column = tableView.tableColumns[tableView.clickedColumn];
  if ([g_columnIDs[column.identifier] intValue] == COL_NAME) {
    NSView *view = [tableView viewAtColumn:tableView.clickedColumn row:tableView.clickedRow makeIfNecessary:NO];
    if (view) {
      NSTextField *text = (NSTextField *)view;
      [text setEditable:YES];
      [text selectText:tableView];
      text.target = self;
      text.action = @selector(freezeTextField:);

      NSText *editor = text.currentEditor;
      BOOL isTextView = [editor isKindOfClass:[NSTextView class]];
      if (isTextView || [editor respondsToSelector:@selector(setInsertionPointColor:)]) {
        [(NSTextView *)editor setInsertionPointColor:_scheme.caretColor];
      }

      if (isTextView || [editor respondsToSelector:@selector(setSelectedTextAttributes:)]) {
        [(NSTextView *)editor setSelectedTextAttributes:
        @{
          NSBackgroundColorAttributeName: _scheme.selectionColor
        }];
      }
    }
  }
}


- (void)freezeTextField:(NSTextField *)field
{
  field.editable = NO;
  field.target = nil;
  field.action = nil;

  if (!_tableView) {
    return;
  }

  NSInteger row = [_tableView rowForView:field];
  // on the off chance this is triggered for a killed row, do a bounds check
  if (row >= 0 && row < [_scheme.rules count]) {
    QSchemeRule *rule = _scheme.rules[row];
    NSString *newName = field.stringValue;

    // Only update it if there's a change.
    if (![rule.name isEqualToString:newName]) {
      rule.name = field.stringValue;
    }
  }
}


- (void)clickedTableView:(NSTableView *)tableView
{
  NSIndexSet *indices = tableView.selectedRowIndexes;
  NSArray *rules = [_scheme.rules objectsAtIndexes:indices];
  NSDictionary * info = @{ QSelectedRules: rules };

  [[NSNotificationCenter defaultCenter]
   postNotificationName:QRuleSelectedNotification
   object:self
   userInfo:info];
}


- (void)updateSelectedRuleSelectors:(NSArray *)selectors
{
  QSchemeRule *rule = self.selectedRule;
  if (rule && ![selectors isEqualTo:rule.selectors]) {
    rule.selectors = selectors;
  }
}


//- (QSchemeRule *)selectedRule
//{
//  if (!_tableView) {
//    return nil;
//  }
//
//  NSIndexSet *indices = _tableView.selectedRowIndexes;
//  NSArray *rules = [_scheme.rules objectsAtIndexes:indices];
//
//  if ([rules count] != 1) {
//    return nil;
//  }
//
//  return rules.lastObject;
//}

@end
