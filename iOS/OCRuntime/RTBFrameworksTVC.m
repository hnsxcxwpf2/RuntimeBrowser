//
//  FrameworksTableViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 01.09.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import "RTBFrameworksTVC.h"
#import "RTBFrameworkCell.h"
#import "RTBRuntime.h"
#import "RTBListTVC.h"
#import "RTBInfoVC.h"

static const NSUInteger kPublicFrameworks = 0;
static const NSUInteger kPrivateFrameworks = 1;

@implementation RTBFrameworksTVC

//- (IBAction)showInfo:(id)sender {
//    
//    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
//    RTBInfoVC *infoVC = (RTBInfoVC *)[sb instantiateViewControllerWithIdentifier:@"RTBInfoVC"];
//    
//    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:infoVC];
//    [self presentViewController:navigationController animated:YES completion:nil];
//}

#pragma mark UISearchController回调: 获取有多少个section
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


#pragma mark UISearchController回调: 获取section对应的标题
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == kPublicFrameworks) return @"Public Frameworks";
    if(section == kPrivateFrameworks) return @"Private Frameworks";
    return nil;
}

#pragma mark UISearchController回调: 获取section对应多少个项目
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == kPublicFrameworks)
    {
        return [_filteredPublicFrameworks count];
    }
    else if (section == kPrivateFrameworks)
    {
        return [_filteredPrivateFrameworks count];
    }
    return 0;
}

#pragma mark UISearchController回调: 根据NSIndexPath创建并返回UITableViewCell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RTBFrameworkCell *cell = (RTBFrameworkCell *)[tableView dequeueReusableCellWithIdentifier:@"RTBFrameworkCell"];
    NSBundle *b = nil;
    if(indexPath.section == kPublicFrameworks)
    {
        b = [_filteredPublicFrameworks objectAtIndex:indexPath.row];
    }
    else
    {
        b = [_filteredPrivateFrameworks objectAtIndex:indexPath.row];
    }
    
    NSString *name = [[[b bundlePath] lastPathComponent] stringByDeletingPathExtension];
    cell.frameworkName = name;
    cell.accessoryType = [b isLoaded] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;   //当前App已加载的Framework打对勾
    return cell;
}

#pragma mark UISearchController回调: 响应点击UITableViewCell事件
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSBundle *b = nil;
    if(indexPath.section == kPublicFrameworks)
    {
        b = [_filteredPublicFrameworks objectAtIndex:indexPath.row];
    }
    else
    {
        b = [_filteredPrivateFrameworks objectAtIndex:indexPath.row];
    }
    
    NSString *bundlePath = [b bundlePath];
    NSString *name = [[bundlePath lastPathComponent] stringByDeletingPathExtension];
    
    if([b isLoaded] == NO)
    {
        NSError *error = nil;
        BOOL success = [b loadAndReturnError:&error];
        
        if(success == NO || [b isLoaded] == NO)
        {
            NSString *alertTitle = [NSString stringWithFormat:@"Error: could not load %@.", name];
            NSString *alertMessage = error ? [error localizedFailureReason] : @"The framework could not be loaded.";
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            return;
        }
        
        [tableView reloadData];
        [_allClasses emptyCachesAndReadAllRuntimeClasses];
    }
    
    NSString *imageName = [[bundlePath lastPathComponent] stringByDeletingPathExtension];
    NSString *imagePath = [bundlePath stringByAppendingPathComponent:imageName];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    RTBListTVC *listTVC = (RTBListTVC *)[sb instantiateViewControllerWithIdentifier:@"RTBListTVC"];
    NSArray *allStubsInImage = [_allClasses.allClassStubsByImagePath valueForKey:imagePath];
    if(allStubsInImage == nil)
        allStubsInImage = [NSArray array];
    listTVC.classStubs = [allStubsInImage sortedArrayUsingSelector:@selector(compare:)];
    listTVC.titleForNavigationItem = name;
    
    [self.navigationController pushViewController:listTVC animated:YES];
}

#pragma mark UISearchController回调: 响应搜索事件
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSString *filter = [searchController.searchBar.text lowercaseString];
	if ([filter length] != 0)
    {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings)
                                                                    {
                                                                        return [[[[[evaluatedObject bundlePath] lastPathComponent] stringByDeletingPathExtension] lowercaseString] containsString:filter];
                                                                    }];
        self.filteredPublicFrameworks = [self.publicFrameworks filteredArrayUsingPredicate:predicate];
        self.filteredPrivateFrameworks = [self.privateFrameworks filteredArrayUsingPredicate:predicate];
    }
    else
    {
        self.filteredPublicFrameworks = self.publicFrameworks;
        self.filteredPrivateFrameworks = self.privateFrameworks;
    }
    dispatch_async(dispatch_get_main_queue(), ^
                                                {
                                                    [self.tableView reloadData];
                                                });
}

#pragma mark 响应Load All Framework按钮
- (IBAction)loadAllFrameworks:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Loading All Frameworks" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    __weak typeof(self) weakSelf = self;
    
    [self presentViewController:alertController animated:YES completion:^
                                                                        {
                                                                            __strong typeof(weakSelf) strongSelf = weakSelf;
                                                                            if(strongSelf == nil) return;
                                                                            CGFloat margin = 8.0;
                                                                            CGFloat progressHeight = 2;
                                                                            strongSelf.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(margin, alertController.view.frame.size.height - progressHeight, alertController.view.frame.size.width - margin * 2.0 , progressHeight)];
                                                                            strongSelf.progressView.progress = 0.0;
                                                                            [alertController.view addSubview:strongSelf.progressView];
                                                                        }];
    
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^
    {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if(strongSelf == nil) return;
        
        NSArray *allFrameworks = [strongSelf.publicFrameworks arrayByAddingObjectsFromArray:strongSelf.privateFrameworks];
        allFrameworks = [allFrameworks arrayByAddingObjectsFromArray:strongSelf.bundleFrameworks];
        
        NSUInteger count = 0;
        NSUInteger total = [allFrameworks count];
        
        for(NSBundle *b in allFrameworks) {
            NSString *bundlePath = [b bundlePath];
#if TARGET_IPHONE_SIMULATOR
            if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_8_0&& [bundlePath isEqualToString:@"/System/Library/PrivateFrameworks/Safari.framework"])
            {
                NSLog(@"-- skip %@, known to be a crasher on simulator", bundlePath);
                continue;
            
            }
            if (NSFoundationVersionNumber >= 1400&& [bundlePath isEqualToString:@"/System/Library/PrivateFrameworks/Spotlight.framework"])
            {
                NSLog(@"-- skip %@, known to be a crasher on simulator", bundlePath);
                continue;
            }
#else
            if (NSFoundationVersionNumber >= 1400)
            {
                static NSSet *skipedFrameworks = nil;
                if (!skipedFrameworks)
                {
                    skipedFrameworks = [NSSet setWithObjects:
                                        @"/System/Library/PrivateFrameworks/PowerlogLiteOperators.framework",
                                        @"/System/Library/PrivateFrameworks/PowerlogCore.framework",
                                        @"/System/Library/PrivateFrameworks/PowerlogHelperdOperators.framework",
                                        @"/System/Library/PrivateFrameworks/PowerlogFullOperators.framework",
                                        @"/System/Library/PrivateFrameworks/PowerlogAccounting.framework",
                                        @"/System/Library/PrivateFrameworks/Accessibility.framework/Frameworks/AXSpringBoardServerInstance.framework", // It will stuck
                                        nil];
                }
                if ([skipedFrameworks containsObject:bundlePath])
                {
                    NSLog(@"-- skip %@, known to be a crasher on device", bundlePath);
                    continue;
                }
            }
#endif
            
            count++;
            float percent = (float)count / (float)total;
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^
                                                                {
                                                                    
                                                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                                                    if(strongSelf == nil) return;
                                                                    
                                                                    strongSelf.progressView.progress = percent;
                                                                }];
            
            @try
            {
                //NSLog(@"-- %@", b);
                NSError *loadError = nil;
                BOOL success = [b loadAndReturnError:&loadError];
                if(success == NO) {
                    //NSLog(@"-- couln't load %@", b);
                    NSLog(@"-- [ERROR] %@", [loadError localizedDescription]);
                }
            }
            @catch (NSException * e)
            {
                NSLog(@"-- exception while loading bundle %@", b);
            }
            @finally
            {
                //do nothing
            }
        }
    }];
    
    [op setCompletionBlock:^
                            {
                                
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^
                                                                                    {
                                                                                        __strong typeof(weakSelf) strongSelf = weakSelf;
                                                                                        if(strongSelf == nil) return;
                                                                                        [strongSelf dismissViewControllerAnimated:YES completion:nil];
                                                                                        [strongSelf.allClasses emptyCachesAndReadAllRuntimeClasses];
                                                                                        [strongSelf.tableView reloadData];
                                                                                        //[self.navigationController.navigationItem setRightBarButtonItem:nil animated:YES];
                                                                                    }];
                            }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:op];
}

#pragma mark 获取某个磁盘目录下的所有framework
- (NSArray *)frameworksAtPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtURL:[NSURL fileURLWithPath:path] includingPropertiesForKeys:@[] options:0 errorHandler:^BOOL(NSURL *url, NSError *error)
                                                                                                                                                                        {
                                                                                                                                                                            NSLog(@"Error for framework at URL %@ -- %@", url, error);
                                                                                                                                                                            return YES;
                                                                                                                                                                        }];
    
    NSMutableArray<NSString *> *frameworks = [NSMutableArray array];
    for( NSURL *fileURL in directoryEnumerator )
    {
        if ( [fileURL.absoluteString.pathExtension isEqualToString:@"framework"] )
        {
            [frameworks addObject:fileURL.relativePath];
        }
    }
    
    NSMutableArray *bundles = [NSMutableArray array];
    for( NSString *frameworkPath in frameworks )
    {
        NSBundle *bundle = [NSBundle bundleWithPath:frameworkPath];
        if( bundle )
        {
            [bundles addObject:bundle];
        }
    }
    
    return bundles;
}

#pragma mark 当前App所加载的Framework
- (NSArray *)loadedBundleFrameworks
{
    NSArray *bundles = [NSBundle allFrameworks];
    NSMutableArray *a = [NSMutableArray array];
    for(NSBundle *b in bundles)
    {
        if([b isLoaded])
        {
            [a addObject:b];
        }
    }
    return a;
}

#pragma mark    setPublicFrameworks
- (void)setPublicFrameworks:(NSArray *)publicFrameworks
{
	_publicFrameworks = publicFrameworks;
	_filteredPublicFrameworks = publicFrameworks;
	[self updateSearchResultsForSearchController:self.searchController];
}

#pragma mark    setPrivateFrameworks
- (void)setPrivateFrameworks:(NSArray *)privateFrameworks
{
	_privateFrameworks = privateFrameworks;
	_filteredPrivateFrameworks = privateFrameworks;
	[self updateSearchResultsForSearchController:self.searchController];
}

#pragma mark    viewDidLoad
- (void)viewDidLoad
{
    self.title = @"Frameworks";
    
    self.allClasses = [RTBRuntime sharedInstance];
    
    self.bundleFrameworks = [self loadedBundleFrameworks];
    
    self.privateFrameworks = [self frameworksAtPath:@"/System/Library/PrivateFrameworks"];
    self.publicFrameworks = [self frameworksAtPath:@"/System/Library/Frameworks"];
	
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	self.definesPresentationContext = YES;
	self.searchController.searchResultsUpdater = self;
	self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
	self.tableView.tableHeaderView = self.searchController.searchBar;
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

//- (void)viewWillDisappear:(BOOL)animated {
//}
//
//- (void)viewDidDisappear:(BOOL)animated {
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end

