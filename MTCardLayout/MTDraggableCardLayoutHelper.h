#import <Foundation/Foundation.h>

@interface MTDraggableCardLayoutHelper : NSObject

@property (nonatomic, readonly) UICollectionViewLayoutAttributes *movingItemAttributes;
@property (nonatomic, readonly) NSIndexPath *toIndexPath;
@property (nonatomic, readonly) CGRect movingItemFrame;
@property (nonatomic, readonly) CGFloat movingItemAlpha;

- (id)initWithCollectionView:(UICollectionView *)collectionView;

@end
