#import <Foundation/Foundation.h>

@interface MTDraggableHelper : NSObject

@property (strong, nonatomic) NSIndexPath *fromIndexPath;
@property (strong, nonatomic) NSIndexPath *toIndexPath;

- (id)initWithCollectionView:(UICollectionView *)collectionView;

@end
