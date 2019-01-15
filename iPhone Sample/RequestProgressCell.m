//
//  RequestProgressCell.m
//  iPhone
//
//  Created by Ben Copsey on 03/10/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import "RequestProgressCell.h"


@implementation RequestProgressCell

+ (id)cell
{
	RequestProgressCell *cell = [[RequestProgressCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"RequestProgressCell"];
	[[cell textLabel] setTextAlignment:NSTextAlignmentLeft];
	[[cell textLabel] setFont:[UIFont systemFontOfSize:12]];
	[[cell textLabel] setLineBreakMode:NSLineBreakByTruncatingMiddle];
	[cell setProgressView:[[UIProgressView alloc] initWithFrame:CGRectMake(0,0,100,20)]];
	[cell setAccessoryView:[cell progressView]];
	return cell;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	CGRect f = [[self accessoryView] frame];
	[[self accessoryView] setFrame:CGRectMake(f.origin.x, f.origin.y+6, f.size.width, f.size.height)];
	
}

@synthesize progressView;
@end
