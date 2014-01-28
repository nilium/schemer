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
  return self.rule ? [self.rule.selectors count] : 0;
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  return self.rule ? self.rule.selectors[row] : nil;
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  if (self.rule) {
    NSMutableArray *selectors = [self.rule.selectors mutableCopy];
    selectors[row] = [object description];
    self.rule.selectors = selectors;
  }
}

@end
