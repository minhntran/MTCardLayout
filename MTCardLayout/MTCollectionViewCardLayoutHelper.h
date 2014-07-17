#import <UIKit/UIKit.h>

@interface MTCollectionViewCardLayoutHelper : NSObject

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, strong) UIImageView *dragUpToDeleteConfirmView;
@property (nonatomic) BOOL presenting;
@property (nonatomic) UIPanGestureRecognizer * panGestureRecognizer;
@property (nonatomic) UITapGestureRecognizer * tapGestureRecognizer;

- (id)initWithCollectionView:(UICollectionView *)collectionView;
- (void)unbindFromCollectionView:(UICollectionView *)collectionView;

@end