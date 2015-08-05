//
//  ThingViewController.m
//  MyOne
//
//  Created by HelloWorld on 7/27/15.
//  Copyright (c) 2015 melody. All rights reserved.
//

#import "ThingViewController.h"
#import "RightPullToRefreshView.h"
#import <unistd.h>
#import "ThingEntity.h"
#import <MJExtension/MJExtension.h>
#import "ThingView.h"
#import "HTTPTool.h"

@interface ThingViewController () <RightPullToRefreshViewDelegate, RightPullToRefreshViewDataSource>

@property (nonatomic, strong) RightPullToRefreshView *rightPullToRefreshView;

@end

@implementation ThingViewController {
	// 当前一共有多少 item，默认为3个
	NSInteger numberOfItems;
	// 保存当前查看过的数据
//	NSMutableArray *readItems;
	NSMutableDictionary *readItems;
	// 测试数据
//	ThingEntity *thingEntity;
	// 最后展示的 item 的下标
	NSInteger lastConfigureViewForItemIndex;
}

#pragma mark - View Lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (self) {
		UIImage *deselectedImage = [[UIImage imageNamed:@"tabbar_item_thing"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
		UIImage *selectedImage = [[UIImage imageNamed:@"tabbar_item_thing_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
		// 底部导航item
		UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:@"东西" image:nil tag:0];
		tabBarItem.image = deselectedImage;
		tabBarItem.selectedImage = selectedImage;
		self.tabBarItem = tabBarItem;
	}
	
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	[self setUpNavigationBarShowRightBarButtonItem:YES];
	
	numberOfItems = 2;
	readItems = [[NSMutableDictionary alloc] init];
	lastConfigureViewForItemIndex = 0;
	
//	[self loadTestData];
	
	self.rightPullToRefreshView = [[RightPullToRefreshView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64 - CGRectGetHeight(self.tabBarController.tabBar.frame))];
	self.rightPullToRefreshView.delegate = self;
	self.rightPullToRefreshView.dataSource = self;
	[self.view addSubview:self.rightPullToRefreshView];
	
	__weak typeof(self) weakSelf = self;
	self.hudWasHidden = ^() {
//		NSLog(@"thing hudWasHidden");
		[weakSelf whenHUDWasHidden];
	};
	
	[self requestThingContentAtIndex:0];
}

#pragma mark - Lifecycle

- (void)dealloc {
	self.rightPullToRefreshView.delegate = nil;
	self.rightPullToRefreshView.dataSource = nil;
	self.rightPullToRefreshView = nil;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - RightPullToRefreshViewDataSource

- (NSInteger)numberOfItemsInRightPullToRefreshView:(RightPullToRefreshView *)rightPullToRefreshView {
	return numberOfItems;
}

- (UIView *)rightPullToRefreshView:(RightPullToRefreshView *)rightPullToRefreshView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
	ThingView *thingView = nil;
	
	//create new view if no view is available for recycling
	if (view == nil) {
		view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(rightPullToRefreshView.frame), CGRectGetHeight(rightPullToRefreshView.frame))];
		thingView = [[ThingView alloc] initWithFrame:view.bounds];
		[view addSubview:thingView];
	} else {
		thingView = (ThingView *)view.subviews[0];
	}
	
	//remember to always set any properties of your carousel item
	//views outside of the `if (view == nil) {...}` check otherwise
	//you'll get weird issues with carousel item content appearing
	//in the wrong place in the carousel
//	NSLog(@"thing viewForItem index = %ld, numberOfItems = %ld, readItems.count = %ld", index, numberOfItems, readItems.count);
	if (index == numberOfItems - 1 || index == readItems.count) {// 当前这个 item 是没有展示过的
//		NSLog(@"thing refresh index = %ld", index);
		[thingView refreshSubviewsForNewItem];
	} else {// 当前这个 item 是展示过了但是没有显示过数据的
//		NSLog(@"thing configure index = %ld", index);
		lastConfigureViewForItemIndex = MAX(index, lastConfigureViewForItemIndex);
		[thingView configureViewWithThingEntity:readItems[[@(index) stringValue]] animated:YES];
	}
	
	return view;
}

#pragma mark - RightPullToRefreshViewDelegate

- (void)rightPullToRefreshViewRefreshing:(RightPullToRefreshView *)rightPullToRefreshView {
	[self showHUDWaitingWhileExecuting:@selector(request)];
}

//- (void)rightPullToRefreshViewDidScrollToLastItem:(RightPullToRefreshView *)rightPullToRefreshView {
//	numberOfItems++;
//	[self.rightPullToRefreshView insertItemAtIndex:(numberOfItems - 1) animated:YES];
//}

- (void)rightPullToRefreshView:(RightPullToRefreshView *)rightPullToRefreshView didDisplayItemAtIndex:(NSInteger)index {
//	NSLog(@"thing didDisplayItemAtIndex index = %ld, numberOfItems = %ld", index, numberOfItems);
	if (index == numberOfItems - 1) {// 如果当前显示的是最后一个，则添加一个 item
//		NSLog(@"thing add new item ----");
		numberOfItems++;
		[self.rightPullToRefreshView insertItemAtIndex:(numberOfItems - 1) animated:YES];
	}
	
	if (index < readItems.count && readItems[[@(index) stringValue]]) {
//		NSLog(@"thing didDisplay configure index = %ld lastConfigureViewForItemIndex = %ld------", index, lastConfigureViewForItemIndex);
		ThingView *thingView = (ThingView *)[rightPullToRefreshView itemViewAtIndex:index].subviews[0];
//		NSLog(@"thing lastConfigureViewForItemIndex < index : %@", lastConfigureViewForItemIndex < index ? @"YES" : @"NO");
//		NSLog(@"thing (!lastConfigureViewForItemIndex && !index) : %@", (!lastConfigureViewForItemIndex && !index) ? @"YES" : @"NO");
		[thingView configureViewWithThingEntity:readItems[[@(index) stringValue]] animated:(lastConfigureViewForItemIndex == 0 || lastConfigureViewForItemIndex < index)];
	} else {
		[self requestThingContentAtIndex:index];
	}
}

#pragma mark - Network Requests

- (void)request {
	sleep(2);
}

- (void)requestThingContentAtIndex:(NSInteger)index {
	NSString *date = [BaseFunction stringDateBeforeTodaySeveralDays:index];
	[HTTPTool requestThingContentByDate:date success:^(AFHTTPRequestOperation *operation, id responseObject) {
		//		NSLog(@"thing responseObject = %@", responseObject);
		if ([responseObject[@"rs"] isEqualToString:REQUEST_SUCCESS]) {
			//			NSLog(@"thing request index = %ld date = %@ success-------", index, date);
			ThingEntity *returnThingEntity = [ThingEntity objectWithKeyValues:responseObject[@"entTg"]];
			[readItems setObject:returnThingEntity forKey:[@(index) stringValue]];
			[self.rightPullToRefreshView reloadItemAtIndex:index animated:NO];
		}
	} failBlock:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"error = %@", error);
	}];
}

#pragma mark - Private

- (void)whenHUDWasHidden {
	[self.rightPullToRefreshView endRefreshing];
}

- (void)loadTestData {
	// 先不做成可变的
//	NSDictionary *testData = [BaseFunction loadTestDatasWithFileName:@"thing_content"];
//	thingEntity = [ThingEntity objectWithKeyValues:testData[@"entTg"]];
//	NSLog(@"thingEntity = %@", thingEntity);
}

#pragma mark - Parent

- (void)share {
	[super share];
//	NSLog(@"share --------");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
