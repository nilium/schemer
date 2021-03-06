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

/* QDocument.m - Noel Cower */

#import "QDocument.h"
#import "QScheme.h"
#import "QSchemeRule.h"
#import "QRulesTableData.h"
#import "QRulesTableDelegate.h"
#import "NSFilters.h"
#import "NSObject+QNull.h"
#import "QSelectorTableSource.h"
#import "QAppDelegate.h"


static NSDragOperation const QDragOpsMask =
  NSDragOperationMove |
  NSDragOperationCopy;


static NSKeyValueObservingOptions const QCaptureObservedChanges =
  NSKeyValueObservingOptionNew |
  NSKeyValueObservingOptionOld;


static
NSArray *
observedSchemePaths()
{
  static NSArray *paths = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    paths = @[
      @"foregroundColor",
      @"backgroundColor",
      @"lineHighlightColor",
      @"selectionColor",
      @"selectionBorderColor",
      @"inactiveSelectionColor",
      @"invisiblesColor",
      @"caretColor",
      @"gutterFGColor",
      @"gutterBGColor",
      @"findHiliteFGColor",
      @"findHiliteBGColor"
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

@implementation QDocument {
  NSInteger _midUpdate;
}

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
      [self addObserver:self
             forKeyPath:@"scheme"
                options:QCaptureObservedChanges
                context:NULL];

      self.scheme = [QScheme new];

      [[NSNotificationCenter defaultCenter]
       addObserver:self selector:@selector(userFontChanged:)
       name:QFontChangeNotification
       object:nil];

      _midUpdate = 0;
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

  self.rulesTableDelegate = [[QRulesTableDelegate alloc]
                             initWithScheme:self.scheme
                                  tableView:self.rulesTable];

  self.rulesTableData = [[QRulesTableData alloc] initWithScheme:self.scheme];

  self.rulesTable.target        = self.rulesTableDelegate;
  self.rulesTable.action        = @selector(clickedTableView:);
  self.rulesTable.doubleAction  = @selector(doubleClickedTableView:);
  self.rulesTable.delegate      = self.rulesTableDelegate;
  self.rulesTable.dataSource    = self.rulesTableData;

  self.rulesTableObserverKey =
    [center addObserverForName:NSTableViewSelectionDidChangeNotification
                        object:self.rulesTable
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:ruleSelectedBlock];

  self.selectorTableObserverKey =
    [center addObserverForName:NSTableViewSelectionDidChangeNotification
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
  [self.rulesTable registerForDraggedTypes:@[QRulePasteType]];
  [self.rulesTable setDraggingSourceOperationMask:QDragOpsMask
                                         forLocal:YES];

  [self bindTableView];
}


+ (BOOL)autosavesInPlace
{
  // Absolutely not.
  return YES;
}


- (BOOL)
  writeToURL:(NSURL *)url
      ofType:(NSString *)typeName
       error:(NSError *__autoreleasing *)outError
{
  NSDictionary *plist = [self.scheme toPropertyList];

  if (!plist) {
    NSDictionary *info = @{
      @"url": url,
      @"type": typeName
    };
    if (outError) {
      *outError = [NSError errorWithDomain:@"QInvalidPList"
                                      code:2
                                  userInfo:info];
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
      *outError = [NSError errorWithDomain:@"QCannotWritePList"
                                      code:3
                                  userInfo:info];
    }
    return NO;
  }

  return YES;
}


- (BOOL)
  readFromURL:(NSURL *)url
       ofType:(NSString *)typeName
        error:(NSError *__autoreleasing *)outError
{
  NSDictionary *plist = [NSDictionary dictionaryWithContentsOfURL:url];

  if (nil == plist) {
    NSDictionary *info = @{
      @"url": url,
      @"type": typeName
    };
    if (outError) {
      *outError = [NSError errorWithDomain:@"QInvalidPList"
                                      code:1
                                  userInfo:info];
    }
    return NO;
  }

  self.scheme = [[QScheme alloc] initWithPropertyList:plist];

  if (self.rulesTable) {
    [self bindTableView];
  }

  return YES;
}


- (BOOL)
  revertToContentsOfURL:(NSURL *)url
                 ofType:(NSString *)typeName
                  error:(NSError *__autoreleasing *)outError
{
  if ([self readFromURL:url ofType:typeName error:outError]) {
    [self updateChangeCount:NSChangeCleared];

    return YES;
  }
  return NO;
}


#pragma mark Key-value observing

- (void)
  observeValueForKeyPath:(NSString *)keyPath
                ofObject:(id)object
                  change:(NSDictionary *)change
                 context:(void *)context
{
  if ([keyPath isEqualToString:@"scheme"]) {
    NSNumber *kind = change[NSKeyValueChangeKindKey];
    switch (kind.unsignedIntegerValue) {
    case NSKeyValueChangeReplacement:
    case NSKeyValueChangeSetting: {
      QScheme *oldScheme = [change[NSKeyValueChangeOldKey] selfIfNotNull];
      QScheme *newScheme = [change[NSKeyValueChangeNewKey] selfIfNotNull];
      [self rebindObservationFromOldScheme:oldScheme
                               toNewScheme:newScheme];
    } break;

    default: break;
    }
  } else if (object == self.scheme) {
    [self updateChangeCount:NSChangeDone];

    if ([keyPath isEqualToString:@"rules"]) {
      NSArray *oldRules = [change[NSKeyValueChangeOldKey] selfIfNotNull];
      NSArray *newRules = [change[NSKeyValueChangeNewKey] selfIfNotNull];
      [self rebindObservationFromOldRules:oldRules toNewRules:newRules];

      if (self.rulesTable && _midUpdate == 0) {
        [self.rulesTable reloadData];
      }
    }
  } else if ([object isKindOfClass:[QSchemeRule class]]) {
    // a rule changed
    [self updateChangeCount:NSChangeDone];
  }
}


- (void)
  rebindObservationFromOldScheme:(QScheme *)oldScheme
                     toNewScheme:(QScheme *)newScheme
{
  [self rebindObservationFromOldObject:oldScheme
                           toNewObject:newScheme
                              forPaths:observedSchemePaths()];

  [self rebindObservationFromOldObject:oldScheme
                           toNewObject:newScheme
                              forPaths:@[@"rules"]
                               options:QCaptureObservedChanges];

  NSArray *oldRules = oldScheme ? oldScheme.rules : nil;
  NSArray *newRules = newScheme ? newScheme.rules : nil;

  [self rebindObservationFromOldRules:oldRules toNewRules:newRules];
}


- (void)
  rebindObservationFromOldRules:(NSArray *)oldRulesArray
                     toNewRules:(NSArray *)newRulesArray
{
  // TODO: Replace rebind with use of addObserver:toObjectsAtIndexes:for...
  NSArray *paths = observedSchemeRulePaths();

  NSSet *oldRules = nil;
  NSSet *newRules = nil;
  NSUInteger oldRulesCount = 0;
  NSUInteger newRulesCount = 0;

  if (oldRulesArray && (oldRulesCount = [oldRulesArray count])) {
    oldRules = [NSSet setWithArray:oldRulesArray];
  } else {
    oldRules = [NSSet set];
  }

  if (newRulesArray && (newRulesCount = [newRulesArray count])) {
    newRules = [NSSet setWithArray:newRulesArray];
  } else {
    newRules = [NSSet set];
  }

  if (oldRulesCount) {
    NSSet *filtered = oldRules;

    if (newRulesCount) {
      filtered = [oldRules rejectedBy:^(id obj) {
        return [newRules containsObject:obj];
      }];
    }

    for (QSchemeRule *rule in filtered) {
      [self rebindObservationFromOldObject:rule toNewObject:nil forPaths:paths];
    }
  }

  if (newRulesCount) {
    NSSet *filtered = newRules;

    if (oldRulesCount) {
      filtered = [newRules rejectedBy:^(id obj) {
        return [oldRules containsObject:obj];
      }];
    }

    for (QSchemeRule *rule in filtered) {
      [self rebindObservationFromOldObject:nil toNewObject:rule forPaths:paths];
    }
  }
}


- (void)
  rebindObservationFromOldObject:(id)oldObject
                     toNewObject:(id)newObject
                        forPaths:(NSArray *)paths
{
  [self rebindObservationFromOldObject:oldObject
                           toNewObject:newObject
                              forPaths:paths
                               options:0];
}


- (void)
  rebindObservationFromOldObject:(id)oldObject
                     toNewObject:(id)newObject
                        forPaths:(NSArray *)paths
                         options:(NSKeyValueObservingOptions)options
{
  if (oldObject) {
    for (NSString *path in paths) {
      [oldObject removeObserver:self forKeyPath:path];
    }
  }

  if (newObject) {
    for (NSString *path in paths) {
      [newObject addObserver:self forKeyPath:path options:options context:NULL];
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


#pragma mark Add / remove rules

- (IBAction)appendNewRule:(id)sender {
  NSTableView *table = self.rulesTable;
  if (table) {
    ++_midUpdate;
    NSUInteger index    = [self.scheme.rules count];
    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:index];

    self.scheme.rules =
      [self.scheme.rules arrayByAddingObject:[QSchemeRule new]];

    [table insertRowsAtIndexes:indices withAnimation:0];
    [table selectRowIndexes:indices byExtendingSelection:NO];
    [table scrollRowToVisible:index];
    --_midUpdate;
  }
}


- (IBAction)removeSelectedRules:(id)sender {
  NSTableView *table = self.rulesTable;
  if (table) {
    NSIndexSet *indices = table.selectedRowIndexes;

    if ([indices count]) {
      ++_midUpdate;
      NSMutableArray *rules = [self.scheme.rules mutableCopy];
      [rules removeObjectsAtIndexes:indices];
      self.scheme.rules = rules;
      [table removeRowsAtIndexes:indices
                   withAnimation:NSTableViewAnimationSlideLeft];
      --_midUpdate;
    }
  }
}


- (IBAction)appendNewSelector:(id)sender {
  NSTableView *table = self.selectorTable;
  QSchemeRule *rule = self.selectorData.rule;
  if (rule && table) {
    [table beginUpdates];
    NSUInteger index    = [rule.selectors count];
    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:index];
    rule.selectors      = [rule.selectors arrayByAddingObject:@"scope"];

    [table insertRowsAtIndexes:indices withAnimation:0];
    [table endUpdates];
    [table selectRowIndexes:indices byExtendingSelection:NO];
    [table scrollRowToVisible:index];
    [table editColumn:0 row:index withEvent:nil select:YES];
  }
}


- (IBAction)removeSelectedSelectors:(id)sender {
  // TODO: Refactor both append/remove methods into calls to something generic
  // for this purpose
  NSTableView *table = self.selectorTable;
  QSchemeRule *rule = self.selectorData.rule;
  if (rule && table) {
    NSIndexSet *indices = table.selectedRowIndexes;

    if ([indices count]) {
      NSMutableArray *selectors = [rule.selectors mutableCopy];
      [selectors removeObjectsAtIndexes:indices];
      [table beginUpdates];
      rule.selectors = selectors;
      [table removeRowsAtIndexes:indices
                   withAnimation:NSTableViewAnimationSlideLeft];
      [table endUpdates];
    }
  }
}

@end
