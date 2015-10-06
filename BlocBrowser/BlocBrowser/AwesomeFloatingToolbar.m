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
@property (strong, nonatomic) NSArray *labels;
@property (weak, nonatomic) UILabel *currentLabel;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
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

        NSMutableArray *labelsArray = [[NSMutableArray alloc] init];
        
        //make the 4 labels
        for (NSString *currentTitle in self.currentTitles) {
            UILabel *label = [[UILabel alloc] init];
            label.userInteractionEnabled = NO;
            label.alpha = 0.25;
            
            //why do this step and not just use currentTitle?
            NSUInteger currentTitleIndex = [self.currentTitles indexOfObject:currentTitle];
            NSString *titleForThisLabel = [self.currentTitles objectAtIndex:currentTitleIndex];
            UIColor *colorForThisLabel = [self.colors objectAtIndex:currentTitleIndex];
            
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont systemFontOfSize:10];
            label.text = titleForThisLabel;
            label.backgroundColor = colorForThisLabel;
            label.textColor = [UIColor whiteColor];
            
            [labelsArray addObject:label];
            
        }
        
        self.labels = labelsArray;
        
        for (UILabel *thisLabel in self.labels) {
            [self addSubview:thisLabel];
        }
        
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFired:)];
        [self addGestureRecognizer:self.tapGesture];
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
    
    for (UILabel *label in self.labels) {
        NSUInteger currentLabelIndex = [self.labels indexOfObject:label];

        CGFloat labelHeight = CGRectGetHeight(self.bounds) / 2;
        CGFloat labelWidth = CGRectGetWidth(self.bounds) / 2;
        CGFloat labelX = 0;
        CGFloat labelY = 0;
        
        if ( currentLabelIndex < 2 ) {
            labelY = 0;
        } else {
            labelY = CGRectGetHeight(self.bounds) / 2 ;
        }
        
        if ( currentLabelIndex % 2 == 0 ) {
            labelX = 0;
        } else {
            labelX = CGRectGetWidth(self.bounds) / 2;
        }
        
        label.frame = CGRectMake(labelX, labelY, labelWidth, labelHeight);
        
    }
    
}

 #pragma mark - Touch Handling

- (UILabel *) labelFromTouches:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    UIView *subView = [self hitTest:location withEvent:event];
    
    if ( [subView isKindOfClass:[UILabel class]] ) {
        return (UILabel *)subView;
    } else {
        return nil;
    }
}

- (void) tapFired:(UITapGestureRecognizer *)recognizer {
    if ( recognizer.state == UIGestureRecognizerStateRecognized ) {
        CGPoint location = [recognizer locationInView:self];
        UIView *tappedView = [self hitTest:location withEvent:nil];
        
        if ( [self.labels containsObject:tappedView] ) {
            if ( [self.delegate respondsToSelector:@selector(floatingToolbar:didSelectButtonWithTitle:)] ) {
                [self.delegate floatingToolbar:self didSelectButtonWithTitle:((UILabel *)tappedView).text];
            }
        }
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
    if ( recognizer.state == UIGestureRecognizerStateRecognized ) {
        CGFloat scale = [recognizer scale];
        NSLog(@"Scaling: %f", scale);
        
        if ( [self.delegate respondsToSelector:@selector(floatingToolbar:didTryToPinchWithScale:)] ) {
            [ self.delegate floatingToolbar:self didTryToPinchWithScale:scale ];
        }
        
        [recognizer setScale:0];
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
        UILabel *label = [self.labels objectAtIndex:index];
        label.userInteractionEnabled = enabled;
        if ( enabled ) {
            label.alpha = 1;
        } else {
            label.alpha = 0.25;
        }
    }
}

#pragma mark - helper methods

- (void) changeButtonColors {
    NSUInteger numberOfColors = self.colors.count;
    for (UILabel *thisLabel in self.labels) {
        UIColor *thisLabelColor = [thisLabel backgroundColor];
        NSUInteger indexOfColor = [self.colors indexOfObject:thisLabelColor];

        if ( indexOfColor < ( numberOfColors - 1 ) ) {
             thisLabel.backgroundColor = [self.colors objectAtIndex: indexOfColor + 1 ];
        } else {
            thisLabel.backgroundColor = [self.colors objectAtIndex:0];
        }
        
    }
}

@end
