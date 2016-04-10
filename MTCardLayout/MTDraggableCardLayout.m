#import "MTDraggableCardLayout.h"
#import "UICollectionView+CardLayout.h"
#import "UICollectionView+DraggableCardLayout.h"
#import "MTDraggableCardLayoutHelper.h"

@interface UICollectionView (DraggableCardLayoutPrivate)

@property (nonatomic, readonly) MTDraggableCardLayoutHelper *draggableCardLayoutHelper;

@end

@interface MTDraggableCardLayout ()

@end

@implementation MTDraggableCardLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *elements = [super layoutAttributesForElementsInRect:rect];
    
    UICollectionView *collectionView = self.collectionView;
    NSIndexPath *fromIndexPath = collectionView.draggableCardLayoutHelper.movingItemAttributes.indexPath;
    NSIndexPath *toIndexPath = collectionView.draggableCardLayoutHelper.toIndexPath;
    
    if (fromIndexPath == nil || toIndexPath == nil) {
        return elements;
    }
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in elements) {
        if(layoutAttributes.representedElementCategory != UICollectionElementCategoryCell) {
            continue;
        }
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        if ([indexPath isEqual:toIndexPath]) {
            // Item's new location
            layoutAttributes.indexPath = fromIndexPath;
            layoutAttributes.frame = CGRectOffset(self.collectionView.draggableCardLayoutHelper.movingItemFrame, 0, -8);
        }
        else if (toIndexPath) {
            if(indexPath.item <= fromIndexPath.item && indexPath.item > toIndexPath.item) {
                // Item moved back
                layoutAttributes.indexPath = [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section];
            }
            else if(indexPath.item >= fromIndexPath.item && indexPath.item < toIndexPath.item) {
                // Item moved forward
                layoutAttributes.indexPath = [NSIndexPath indexPathForItem:indexPath.item + 1 inSection:indexPath.section];
            }
        }
    }
    
    return elements;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *finalAttributes = [super finalLayoutAttributesForDisappearingItemAtIndexPath:indexPath];
    UICollectionViewLayoutAttributes *movingItemAttributes = self.collectionView.draggableCardLayoutHelper.movingItemAttributes;

    if ([movingItemAttributes.indexPath isEqual:indexPath] &&
        self.collectionView.draggableCardLayoutHelper.toIndexPath == nil) {
        finalAttributes.frame = self.collectionView.draggableCardLayoutHelper.movingItemFrame;
    }

    return finalAttributes;
}

@end
