//
//  AwesomeFloatingToolbar.h
//  BlocBrowser
//
//  Created by Ryan Walker on 10/5/15.
//  Copyright © 2015 Ryan Walker. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AwesomeFloatingToolbar;

@protocol AwesomeFloatingToolbarDelegate <NSObject>

@optional

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title;

@end

@interface AwesomeFloatingToolbar : UIView

- (instancetype) initWithFourTitles:(NSArray *)titles;
- (void) setEnabled:(BOOL)enabled forButtonWithTile:(NSString *)title;

@property (nonatomic, weak) id <AwesomeFloatingToolbarDelegate> delegate;

@end
