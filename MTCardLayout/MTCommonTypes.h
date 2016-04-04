#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MTCardLayoutViewMode) {
    MTCardLayoutViewModeDefault,
    MTCardLayoutViewModePresenting
};

typedef struct
{
    // Insets of the fullscreen card
    UIEdgeInsets presentingInsets;
    
    // Insets of the list
    UIEdgeInsets listingInsets;
    
    // Top flexible inset
    CGFloat flexibleTop;
    // The visible size of each card in the normal stack
    CGFloat minimumVisibleHeight;
    // The visible size of each card in the bottom stack
    CGFloat stackedVisibleHeight;
    // Max number of card to show at the bottom stack
    NSUInteger maxStackedCards;
    
    // This value is calculated internally
    CGFloat visibleHeight;
} MTCardLayoutMetrics;

typedef struct
{
    /// How much of the pulling is translated into movement on the top. An inheritance of 0 disables this feature (same as bouncesTop)
    CGFloat inheritance;
    
    /// Allows for bouncing when reaching the top
    BOOL bouncesTop;
    
    /// Allows the cards get "stuck" on the top, instead of just scrolling outside
    BOOL sticksTop;
    
    /// Allows the cards to spread out when there is less number of cards
    BOOL spreading;
    
    /// Allows all cards to collapse to the bottom
    BOOL collapsesAll;
    
} MTCardLayoutEffects;

@protocol UICollectionViewDataSource_Draggable <UICollectionViewDataSource>
@required

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(UICollectionView *)collectionView canDeleteItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

- (void)collectionView:(UICollectionView *)collectionView deleteItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol UICollectionViewDelegate_Draggable <UICollectionViewDelegate>

@optional

- (void)collectionViewDidChangeViewMode:(UICollectionView *)collectionView;

- (void)collectionView:(UICollectionView *)collectionView modifyMovingItemAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes;

- (void)collectionView:(UICollectionView *)collectionView didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView didDeleteItemAtIndexPath:(NSIndexPath *)indexPath;

- (UIView *)collectionView:(UICollectionView *)collectionView deletionConfirmationViewForItemAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)collectionView:(UICollectionView *)collectionView shouldRecognizeTapGestureAtPoint:(CGPoint)point;
- (BOOL)collectionView:(UICollectionView *)collectionView shouldRecognizePanGestureAtPoint:(CGPoint)point;

@end
