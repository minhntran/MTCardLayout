#import <UIKit/UIKit.h>

typedef struct
{
    /// Size of a state of a card
    CGSize size;
    
    /// Amount of "pixels" of overlap between this card and others.
    CGFloat overlap;
} MTCardMetrics;

typedef struct
{
	CGFloat flexibleTopMaxHeight;
	CGFloat flexibleTopMinHeight;
	
    /// Normal is the real size of the selected card ("full screen" display)
    MTCardMetrics normal;
    
    /// Collapsed is the size of cards in the list with no card selected
    MTCardMetrics collapsed;
    
    /// The size of the bottom stack when a card is selected and all others are stacked at bottom
    CGFloat bottomStackedTotalHeight;
    
    /// The visible size of each card in the bottom stack
    CGFloat bottomStackedHeight;
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
