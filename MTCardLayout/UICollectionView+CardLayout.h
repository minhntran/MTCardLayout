#import <UIKit/UIKit.h>

@interface UICollectionView (CardLayout)

@property (nonatomic, strong) UIImageView * dragUpToDeleteConfirmView;
@property (nonatomic) BOOL presenting;

@property (nonatomic, readonly) UITapGestureRecognizer *cardLayoutTapGestureRecognizer;
@property (nonatomic, readonly) UIPanGestureRecognizer *cardLayoutPanGestureRecognizer;

- (void)setPresenting:(BOOL)presenting animated:(BOOL)animated completion:(void (^)(BOOL))completion;

@end

@interface UICollectionViewCell(CardLayout)

- (void)flipTransitionWithOptions:(UIViewAnimationOptions)options halfway:(void (^)(BOOL finished))halfway completion:(void (^)(BOOL finished))completion;

@end