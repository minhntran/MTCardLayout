#import <Foundation/Foundation.h>

@interface MTDraggableHelper : NSObject

@property (nonatomic, readonly) UICollectionViewLayoutAttributes *movingItemAttributes;
@property (nonatomic, readonly) NSIndexPath *toIndexPath;
@property (nonatomic, readonly) CGRect movingItemFrame;

- (id)initWithCollectionView:(UICollectionView *)collectionView;

@end
