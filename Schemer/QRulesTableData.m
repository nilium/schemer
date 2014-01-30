//
//  QRulesTableData.m
//  Schemer
//
//  Created by Noel Cower on 01/27/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "QRulesTableData.h"
#import "QScheme.h"
#import "QSchemeRule.h"
#import "NSFilters.h"


NSString *const QRulePasteType = @"net.spifftastic.schemer.paste.rule";


@implementation QRulesTableData {
  QScheme *_scheme;
}


- (id)initWithScheme:(QScheme *)scheme
{
  if ((self = [self init])) {
    _scheme = scheme;
  }
  return self;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [_scheme.rules count];
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  // Used to return the actual data for the column, but it's not really being used, this just
  // returns nil, now, since doing otherwise would cause the tableView to try to set the object
  // value of the controls to something and that's not pretty.
  return nil;
}


#pragma mark Drag / drop support

- (BOOL)tableView:(NSTableView *)tableView
       acceptDrop:(id<NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)dropOperation
{
  if (dropOperation == NSTableViewDropOn) {
    return NO;
  }

  NSUInteger mask = [info draggingSourceOperationMask];
  id source = [info draggingSource];
  NSPasteboard *paste = [info draggingPasteboard];

  NSArray *items = [[paste readObjectsForClasses:@[[NSPasteboardItem class]] options:nil]
                    mappedTo:^id(id obj) {
                      return [obj propertyListForType:QRulePasteType];
                    }];

  NSMutableIndexSet *indices = [NSMutableIndexSet new];

  if (source == tableView && mask & NSDragOperationMove) {
    for (NSDictionary *item in items) {
      NSInteger itemRow = [item[@"row"] integerValue];
      [indices addIndex:itemRow];
      if (itemRow < row) {
        row -= 1;
      }
    }
  }

  NSMutableArray *rules = [_scheme.rules mutableCopy];
  [rules removeObjectsAtIndexes:indices];
  NSArray *newRules = [items mappedTo:^id(NSDictionary *item) {
    return [[QSchemeRule alloc] initWithPropertyList:item[@"rule"]];
  }];

  NSInteger count = (NSInteger)[rules count];
  if (row >= count) {
    [rules addObjectsFromArray:newRules];
  } else {
    NSIndexSet *newRuleIndices =
      [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [newRules count])];

    [rules insertObjects:newRules atIndexes:newRuleIndices];
  }

  _scheme.rules = rules;
  

  return YES;
}


- (NSDragOperation)tableView:(NSTableView *)tableView
                validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
  if (dropOperation != NSTableViewDropAbove) {
    [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
  }

  if (row >= 0 && row <= [_scheme.rules count]) {
    id source = [info draggingSource];
    NSUInteger mask = [info draggingSourceOperationMask];

    if (mask == NSDragOperationCopy || (source != tableView && (mask & NSDragOperationCopy))) {
      return NSDragOperationCopy;
    }

    if (mask & NSDragOperationMove && source == tableView) {
      return NSDragOperationMove;
    }
  }

  return NSDragOperationNone;
}


- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
  NSPasteboardItem *item = [NSPasteboardItem new];
  [item setPropertyList:@{ @"row": @(row), @"rule": [_scheme.rules[row] toPropertyList] }
                forType:QRulePasteType];
  return item;
}


@end
