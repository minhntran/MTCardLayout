#import "MTDraggableCardLayout.h"
#import "UICollectionView+CardLayout.h"
#import "UICollectionView+DraggableCardLayout.h"
#import "MTDraggableHelper.h"

@interface UICollectionView (DraggableCardLayoutPrivate)

@property (nonatomic, readonly) MTDraggableHelper *draggableHelper;

@end

@interface MTDraggableCardLayout ()

@end

@implementation MTDraggableCardLayout

- (void)modifyAttributesForFocusedItem:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    layoutAttributes.frame = self.collectionView.draggableHelper.movingItemFrame;
    
    id<UICollectionViewDelegate_Draggable> delegate = (id<UICollectionViewDelegate_Draggable>)self.collectionView.delegate;
    if ([delegate respondsToSelector:@selector(collectionView:modifyMovingItemAttributes:)]) {
        [delegate collectionView:self.collectionView modifyMovingItemAttributes:layoutAttributes];
    }
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *elements = [super layoutAttributesForElementsInRect:rect];
    
    UICollectionView *collectionView = self.collectionView;
    NSIndexPath *fromIndexPath = collectionView.draggableHelper.movingItemAttributes.indexPath;
    NSIndexPath *toIndexPath = collectionView.draggableHelper.toIndexPath;
    
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
            [self modifyAttributesForFocusedItem:layoutAttributes];
        }
        else {
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

@end
