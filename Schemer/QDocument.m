//
//  QDocument.m
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "QDocument.h"
#import "QScheme.h"
#import "QSchemeRule.h"
#import "QRulesTableData.h"
#import "QRulesTableDelegate.h"
#import "NSFilters.h"
#import "NSObject+QNull.h"
#import "QSelectorTableSource.h"
#import "QAppDelegate.h"


static
NSArray *
cleanedRuleSelectorArray(NSString *selectors)
{
  static NSCharacterSet *trimset = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    trimset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  });

  return
    [[selectors componentsSeparatedByString:@","]
     mappedArrayUsingBlock:^(id obj) { return [obj stringByTrimmingCharactersInSet:trimset]; }];
}


static
NSArray *
observedSchemePaths()
{
  static NSArray *paths = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    paths =
    @[
      @"foregroundColor",
      @"backgroundColor",
      @"lineHighlightColor",
      @"selectionColor",
      @"selectionBorderColor",
      @"inactiveSelectionColor",
      @"invisiblesColor",
      @"caretColor"
    ];
  });
  return paths;
}


static NSArray *observedSchemeRulePaths()
{
  static NSArray *paths = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    paths = @[
      @"name",
      @"selectors",
      @"foreground",
      @"background",
      @"flags"
    ];
  });
  return paths;
}


#pragma mark Private API for QRulesTableDelegate

@interface QRulesTableDelegate ()

@property (weak, readwrite) QSchemeRule *selectedRule;

@end


#pragma mark Private interface

@interface QDocument ()

@property (strong, readwrite) QScheme *scheme;
@property (weak) IBOutlet NSTableView *rulesTable;
@property (strong) QRulesTableData *rulesTableData;
@property (strong) QRulesTableDelegate *rulesTableDelegate;
@property (weak) IBOutlet NSTokenField *ruleScopeField;
@property (weak) IBOutlet NSButton *removeSelectedRulesButton;
@property (weak) IBOutlet NSTableView *selectorTable;
@property (strong) IBOutlet QSelectorTableSource *selectorData;
@property (weak) IBOutlet NSButton *removeSelectorsButton;

@property (strong) id rulesTableObserverKey;
@property (strong) id selectorTableObserverKey;

@end


#pragma mark Implementation

@implementation QDocument

- (void)dealloc
{
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

  if (self.rulesTableObserverKey) {
    [center removeObserver:self.rulesTableObserverKey];
  }

  if (self.selectorTableObserverKey) {
    [center removeObserver:self.selectorTableObserverKey];
  }

  self.scheme = nil;

  [self removeObserver:self forKeyPath:@"scheme"];
  [center removeObserver:self name:QFontChangeNotification object:nil];
}


- (id)init
{
    if ((self = [super init])) {
      NSUInteger options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
      [self addObserver:self forKeyPath:@"scheme" options:options context:NULL];
      self.scheme = [[QScheme alloc] initWithDocument:self];

      [[NSNotificationCenter defaultCenter]
       addObserver:self selector:@selector(userFontChanged:)
       name:QFontChangeNotification
       object:nil];
    }
    return self;
}


- (void)userFontChanged:(NSNotification *)note
{
  NSTableView *rulesTable = self.rulesTable;
  if (rulesTable) {
    [rulesTable reloadData];
  }
}


- (void)bindTableView
{
  [self refreshTableAppearance];

  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

  if (self.rulesTableObserverKey) {
    [center removeObserver:self.rulesTableObserverKey];
    self.rulesTableObserverKey = nil;
  }

  if (self.selectorTableObserverKey) {
    [center removeObserver:self.selectorTableObserverKey];
    self.selectorTableObserverKey = nil;
  }

  __weak NSButton *removeSelectorsButton = self.removeSelectorsButton;
  void (^selectorSelectedBlock)(NSNotification *) = ^(NSNotification *note) {
    NSTableView *view = (NSTableView *)note.object;
    removeSelectorsButton.enabled = view && [view numberOfSelectedRows] > 0;
  };

  __weak NSTableView *selectorTable = self.selectorTable;
  __weak NSButton *removeRulesButton = self.removeSelectedRulesButton;
  __weak QSelectorTableSource *selectorData = self.selectorData;
  void (^ruleSelectedBlock)(NSNotification *) = ^(NSNotification *note) {
    NSTableView *view = (NSTableView *)note.object;
    NSIndexSet *indices = view ? view.selectedRowIndexes : nil;
    QRulesTableDelegate *delegate = view ? [note.object delegate] : nil;
    removeRulesButton.enabled = indices && [indices count] > 0;

    if (delegate) {
      if ([indices count] == 1) {
        QSchemeRule *rule = self.scheme.rules[indices.lastIndex];
        delegate.selectedRule = rule;
        selectorData.rule = rule;
      } else {
        delegate.selectedRule = nil;
        selectorData.rule = nil;
      }
      [selectorTable reloadData];
    }
  };

  self.selectorTable.dataSource = self.selectorData;
  self.rulesTableDelegate = [[QRulesTableDelegate alloc] initWithScheme:self.scheme tableView:self.rulesTable];
  self.rulesTableData = [[QRulesTableData alloc] initWithScheme:self.scheme];
  self.rulesTable.target = self.rulesTableDelegate;
  self.rulesTable.action = @selector(clickedTableView:);
  self.rulesTable.doubleAction = @selector(doubleClickedTableView:);
  self.rulesTable.delegate = self.rulesTableDelegate;
  self.rulesTable.dataSource = self.rulesTableData;

  self.rulesTableObserverKey = [center addObserverForName:NSTableViewSelectionDidChangeNotification
                                         object:self.rulesTable
                                          queue:[NSOperationQueue mainQueue]
                                     usingBlock:ruleSelectedBlock];

  self.selectorTableObserverKey = [center addObserverForName:NSTableViewSelectionDidChangeNotification
                                                      object:self.selectorTable
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:selectorSelectedBlock];
}


#pragma mark NSDocument

+ (BOOL)usesUbiquitousStorage
{
  return NO;
}


- (NSString *)windowNibName
{
  return @"QDocument";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
  [super windowControllerDidLoadNib:aController];

  self.ruleScopeField.delegate = self;

  [self bindTableView];
}


+ (BOOL)autosavesInPlace
{
  // Absolutely not.
  return YES;
}


- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
  NSDictionary *plist = [self.scheme toPropertyList];

  if (!plist) {
    NSDictionary *info = @{
      @"url": url,
      @"type": typeName
    };
    if (outError) {
      *outError = [NSError errorWithDomain:@"QInvalidPList" code:2 userInfo:info];
    }
    return NO;
  }

  NSString *name = [url.lastPathComponent stringByDeletingPathExtension];
  NSMutableDictionary *plistWithName = [plist mutableCopy];
  plistWithName[@"name"] = name;

  if (![plistWithName writeToURL:url atomically:NO]) {
    NSDictionary *info = @{
      @"url": url,
      @"type": typeName
    };
    if (outError) {
      *outError = [NSError errorWithDomain:@"QCannotWritePList" code:3 userInfo:info];
    }
    return NO;
  }

  return YES;
}


- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
  NSDictionary *plist = [NSDictionary dictionaryWithContentsOfURL:url];

  if (nil == plist) {
    NSDictionary *info = @{
      @"url": url,
      @"type": typeName
    };
    if (outError) {
      *outError = [NSError errorWithDomain:@"QInvalidPList" code:1 userInfo:info];
    }
    return NO;
  }

  self.scheme = [[QScheme alloc] initWithPropertyList:plist document:self];

  if (self.rulesTable) {
    [self bindTableView];
  }

  return YES;
}


- (BOOL)revertToContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
  if ([self readFromURL:url ofType:typeName error:outError]) {
    [self updateChangeCount:NSChangeCleared];

    return YES;
  }
  return NO;
}


#pragma mark Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:@"scheme"]) {
    NSNumber *kind = change[NSKeyValueChangeKindKey];
    switch (kind.unsignedIntegerValue) {
    case NSKeyValueChangeReplacement:
    case NSKeyValueChangeSetting:
      [self rebindObservationFromOldScheme:[change[NSKeyValueChangeOldKey] selfIfNotNull]
                               toNewScheme:[change[NSKeyValueChangeNewKey] selfIfNotNull]];
      break;
    default: break;
    }
  } else if (object == self.scheme) {
    [self updateChangeCount:NSChangeDone];

    if ([keyPath isEqualToString:@"rules"]) {
      [self rebindObservationFromOldRules:[change[NSKeyValueChangeOldKey] selfIfNotNull]
                               toNewRules:[change[NSKeyValueChangeNewKey] selfIfNotNull]];

      if (self.rulesTable) {
        [self.rulesTable reloadData];
      }
    }
  } else if ([object isKindOfClass:[QSchemeRule class]]) {
    // a rule changed
    [self updateChangeCount:NSChangeDone];
  }
}


- (void)rebindObservationFromOldScheme:(QScheme *)oldScheme toNewScheme:(QScheme *)newScheme
{
  [self rebindObservationFromOldObject:oldScheme
                           toNewObject:newScheme
                              forPaths:observedSchemePaths()];

  NSArray *oldRules = oldScheme ? oldScheme.rules : nil;
  NSArray *newRules = newScheme ? newScheme.rules : nil;

  [self rebindObservationFromOldRules:oldRules toNewRules:newRules];
}


- (void)rebindObservationFromOldRules:(NSArray *)oldRulesArray toNewRules:(NSArray *)newRulesArray
{
  NSArray *paths = observedSchemeRulePaths();

  NSSet *oldRules = nil;
  NSSet *newRules = nil;

  if (oldRulesArray && [oldRulesArray count]) {
    oldRules = [NSSet setWithArray:oldRulesArray];
  } else {
    oldRules = [NSSet set];
  }

  if (newRulesArray && [newRulesArray count]) {
    newRules = [NSSet setWithArray:newRulesArray];
  } else {
    newRules = [NSSet set];
  }

  if ([oldRules count]) {
    NSSet *filtered =
      [newRules count]
      ? [oldRules rejectedSetUsingBlock:^(id obj) { return [newRules containsObject:obj]; }]
      : oldRules;

    for (QSchemeRule *rule in filtered) {
      [self rebindObservationFromOldObject:rule toNewObject:nil forPaths:paths];
    }
  }

  if ([newRules count]) {
    NSSet *filtered =
      [oldRules count]
      ? [newRules rejectedSetUsingBlock:^(id obj) { return [oldRules containsObject:obj]; }]
      : newRules;

    for (QSchemeRule *rule in filtered) {
      [self rebindObservationFromOldObject:nil toNewObject:rule forPaths:paths];
    }
  }
}


- (void)rebindObservationFromOldObject:(id)oldObject toNewObject:(id)newObject forPaths:(NSArray *)paths
{
  if (oldObject) {
    for (NSString *path in paths) {
      [oldObject removeObserver:self forKeyPath:path];
    }
  }

  if (newObject) {
    for (NSString *path in paths) {
      [newObject addObserver:self forKeyPath:path options:0 context:NULL];
    }
  }
}


#pragma mark Actions

- (void) refreshTableAppearance
{
  self.rulesTable.backgroundColor = self.scheme.backgroundColor;
  [self.rulesTable reloadData];
}


- (IBAction)modifyColorWell:(id)sender
{
  [self refreshTableAppearance];
}


#pragma mark Edit rule scope

- (void)controlTextDidChange:(NSNotification *)obj
{
  id sender = obj.object;
  if ([sender isKindOfClass:[NSTokenField class]]) {
    [self updateRuleScope:sender];
  }
}


- (IBAction)updateRuleScope:(NSTokenField *)sender
{
  [self.rulesTableDelegate updateSelectedRuleSelectors:cleanedRuleSelectorArray(sender.stringValue)];
}


#pragma mark Add / remove rules

- (IBAction)appendNewRule:(id)sender {
  NSTableView *table = self.rulesTable;
  if (table) {
    self.scheme.rules = [self.scheme.rules arrayByAddingObject:[[QSchemeRule alloc] initWithDocument:self]];
    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:[self.scheme.rules count] - 1];
    [table insertRowsAtIndexes:indices withAnimation:0];
    [table selectRowIndexes:indices byExtendingSelection:NO];
    [table scrollRowToVisible:indices.lastIndex];
  }
}


- (IBAction)removeSelectedRules:(id)sender {
  NSTableView *table = self.rulesTable;
  if (table) {
    NSIndexSet *indices = table.selectedRowIndexes;

    if ([indices count]) {
      NSMutableArray *rules = [self.scheme.rules mutableCopy];
      [rules removeObjectsAtIndexes:indices];
      self.scheme.rules = rules;
      [table removeRowsAtIndexes:indices withAnimation:NSTableViewAnimationSlideLeft];
    }
  }
}


- (IBAction)appendNewSelector:(id)sender {
  NSTableView *table = self.selectorTable;
  QSchemeRule *rule = self.selectorData.rule;
  if (rule && table) {
    [table beginUpdates];
    rule.selectors = [rule.selectors arrayByAddingObject:@"scope"];
    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:[rule.selectors count] - 1];
    [table insertRowsAtIndexes:indices withAnimation:0];
    [table endUpdates];
    [table selectRowIndexes:indices byExtendingSelection:NO];
    [table scrollRowToVisible:indices.lastIndex];
    [table editColumn:0 row:indices.lastIndex withEvent:nil select:YES];
  }
}


- (IBAction)removeSelectedSelectors:(id)sender {
  // TODO: Refactor both append/remove methods into calls to something generic for this purpose
  NSTableView *table = self.selectorTable;
  QSchemeRule *rule = self.selectorData.rule;
  if (rule && table) {
    NSIndexSet *indices = table.selectedRowIndexes;

    if ([indices count]) {
      NSMutableArray *selectors = [rule.selectors mutableCopy];
      [selectors removeObjectsAtIndexes:indices];
      [table beginUpdates];
      rule.selectors = selectors;
      [table removeRowsAtIndexes:indices withAnimation:NSTableViewAnimationSlideLeft];
      [table endUpdates];
    }
  }
}

@end
