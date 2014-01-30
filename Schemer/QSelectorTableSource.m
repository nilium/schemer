//
//  QStringArraySource.m
//  Schemer
//
//  Created by Noel Cower on 01/27/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "QSelectorTableSource.h"
#import "QSchemeRule.h"


@implementation QSelectorTableSource


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  if (self.rule) {
    return self.rule.selectors.count;
  }

  return 0;
}


- (id)
                  tableView:(NSTableView *)tableView
  objectValueForTableColumn:(NSTableColumn *)tableColumn
                        row:(NSInteger)row
{
  if (self.rule) {
    NSArray *selectors = self.rule.selectors;
    if (row >= 0 && row < [selectors count]) {
      return selectors[row];
    }
  }

  return nil;
}


- (void)
       tableView:(NSTableView *)tableView
  setObjectValue:(id)object
  forTableColumn:(NSTableColumn *)tableColumn
             row:(NSInteger)row
{
  if (object && self.rule) {
    NSString *selector = nil;

    if ([object isKindOfClass:[NSString class]]) {
      selector = [object copy];
    } else {
      selector = [object description];
    }

    NSMutableArray *selectors = [self.rule.selectors mutableCopy];
    selectors[row] = selector;
    self.rule.selectors = selectors;
  }
}

@end
