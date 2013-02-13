//
//  VideoInfoViewController.h
//  Harlem Shake
//
//  Created by Jason Fieldman on 2/12/13.
//  Copyright (c) 2013 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoInfoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
	/* Array that contains the table cells */
	NSMutableArray *_tableCells;
	
	/* Table view */
	UITableView *_tableView;
}

@property (nonatomic, strong) VideoID_t videoId;

@end