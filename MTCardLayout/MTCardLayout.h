#import <UIKit/UIKit.h>

typedef struct
{
    // Insets of the fullscreen card
    UIEdgeInsets insets;
    // Top flexible inset
	CGFloat flexibleTopMaxHeight;
    // The visible size of each card in the normal stack
    CGFloat normalStackedHeight;
    // The visible size of each card in the bottom stack
    CGFloat bottomStackedHeight;
	// Max number of card to show at the bottom stack
    NSUInteger maxBottomCards;
    
} MTCardLayoutMetrics;

typedef struct
{
    /// How much of the pulling is translated into movement on the top. An inheritance of 0 disables this feature (same as bouncesTop)
    CGFloat inheritance;
    
    /// Allows for bouncing when reaching the top
    BOOL bouncesTop;
    
    /// Allows the cards get "stuck" on the top, instead of just scrolling outside
    BOOL sticksTop;
    
} MTCardLayoutEffects;

@interface MTCardLayout : UICollectionViewLayout

@property (nonatomic, assign) MTCardLayoutMetrics metrics;
@property (nonatomic, assign) MTCardLayoutEffects effects;

@end
