//
//  AwesomeFloatingToolbar.m
//  BlocBrowser
//
//  Created by Ryan Walker on 10/5/15.
//  Copyright © 2015 Ryan Walker. All rights reserved.
//

#import "AwesomeFloatingToolbar.h"

@interface AwesomeFloatingToolbar ()

@property (strong, nonatomic) NSArray *currentTitles;
@property (strong, nonatomic) NSArray *colors;
@property (strong, nonatomic) NSArray *buttons;
@property (weak, nonatomic) UIButton *currentButton;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinchGesture;
@property (strong, nonatomic) UILongPressGestureRecognizer *pressGesture;

@end

@implementation AwesomeFloatingToolbar

- (instancetype) initWithFourTitles:(NSArray *)titles {
    //setup super class
    self = [super init];
    
    //declare the four titles and associated information
    if (self) {
        
        self.currentTitles = titles;
        self.colors = @[[UIColor colorWithRed:199/255.0 green:158/255.0 blue:203/255.0 alpha:1],
                        [UIColor colorWithRed:255/255.0 green:105/255.0 blue:97/255.0 alpha:1],
                        [UIColor colorWithRed:222/255.0 green:165/255.0 blue:164/255.0 alpha:1],
                        [UIColor colorWithRed:255/255.0 green:179/255.0 blue:71/255.0 alpha:1]];

        NSMutableArray *buttonsArray = [[NSMutableArray alloc] init];
        
        //make the 4 labels
        for (NSString *currentTitle in self.currentTitles) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
            button.userInteractionEnabled = YES;
            button.alpha = 0.25;
            
            //why do this step and not just use currentTitle?
            NSUInteger currentTitleIndex = [self.currentTitles indexOfObject:currentTitle];
            NSString *titleForThisButton = [self.currentTitles objectAtIndex:currentTitleIndex];
            UIColor *colorForThisButton = [self.colors objectAtIndex:currentTitleIndex];
            
            button.titleLabel.font = [UIFont systemFontOfSize:10];
            button.tintColor = [UIColor whiteColor];
            [button setTitle:titleForThisButton forState:UIControlStateNormal];
            button.backgroundColor = colorForThisButton;
            
            [buttonsArray  addObject:button];
            
        }
        
        self.buttons = buttonsArray;
        
        for (UIButton *thisButton in self.buttons) {
            [self addSubview:thisButton];
        }
        
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panFired:)];
        [self addGestureRecognizer:self.panGesture];
        self.pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchFired:)];
        [self addGestureRecognizer:self.pinchGesture];
        self.pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressFired:)];
        [self addGestureRecognizer:self.pressGesture];
    }
    
    return self;
    
}

- (void) layoutSubviews {
    
    //set frame
    
    for (UIButton *button in self.buttons) {
        NSUInteger currentButtonIndex = [self.buttons indexOfObject:button];

        CGFloat buttonHeight = CGRectGetHeight(self.bounds) / 2;
        CGFloat buttonWidth = CGRectGetWidth(self.bounds) / 2;
        CGFloat buttonX = 0;
        CGFloat buttonY = 0;
        
        if ( currentButtonIndex < 2 ) {
            buttonY = 0;
        } else {
            buttonY = CGRectGetHeight(self.bounds) / 2 ;
        }
        
        if ( currentButtonIndex % 2 == 0 ) {
            buttonX = 0;
        } else {
            buttonX = CGRectGetWidth(self.bounds) / 2;
        }
        
        button.frame = CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight);
        
    }
    
}

 #pragma mark - Touch Handling

- (void) buttonPressed:(UIButton *)button {
    if ( [self.delegate respondsToSelector:@selector(floatingToolbar:didTapButton:)]) {
        [self.delegate floatingToolbar:self didTapButton:button];
    }
}

- (void) panFired:(UIPanGestureRecognizer *)recognizer {
    if ( recognizer.state == UIGestureRecognizerStateRecognized ) {
        CGPoint translation = [recognizer translationInView:self];
        NSLog(@"New translation: %@", NSStringFromCGPoint(translation));
        
        if ( [self.delegate respondsToSelector:@selector(floatingToolbar:didTryToPanWithOffset:) ]) {
            [self.delegate floatingToolbar:self didTryToPanWithOffset:translation];
        }
        
        [recognizer setTranslation:CGPointZero inView:self];
    }
}

- (void) pinchFired:(UIPinchGestureRecognizer *)recognizer {
    if ( recognizer.state == UIGestureRecognizerStateChanged ) {
        CGFloat scale = [recognizer scale];
        NSLog(@"Scaling: %f", scale);
        
        if ( [self.delegate respondsToSelector:@selector(floatingToolbar:didTryToPinchWithScale:)] ) {
            [ self.delegate floatingToolbar:self didTryToPinchWithScale:scale ];
        }
        
        [recognizer setScale:1];
    }
}

- (void) pressFired:(UILongPressGestureRecognizer *)recognizer {
    if ( recognizer.state == UIGestureRecognizerStateRecognized ) {
        [self changeButtonColors];
    }
}

 #pragma mark - Button Enabling

- (void) setEnabled:(BOOL)enabled forButtonWithTile:(NSString *)title {
    NSUInteger index = [self.currentTitles indexOfObject:title];
    
    if (index != NSNotFound) {
        UIButton *button = [self.buttons objectAtIndex:index];
        button.userInteractionEnabled = enabled;
        if ( enabled ) {
            button.alpha = 1;
        } else {
            button.alpha = 0.25;
        }
    }
}

#pragma mark - helper methods

- (void) changeButtonColors {
    NSUInteger numberOfColors = self.colors.count;
    for (UIButton *thisButton in self.buttons) {
        UIColor *thisButtonColor = [thisButton backgroundColor];
        NSUInteger indexOfColor = [self.colors indexOfObject:thisButtonColor];

        if ( indexOfColor < ( numberOfColors - 1 ) ) {
             thisButton.backgroundColor = [self.colors objectAtIndex: indexOfColor + 1 ];
        } else {
            thisButton.backgroundColor = [self.colors objectAtIndex:0];
        }
        
    }
}

@end
