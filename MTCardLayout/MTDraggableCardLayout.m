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
    if ([self.collectionView.dataSource respondsToSelector:@selector(collectionView:modifyDraggingItemAttributes:)]) {
        id<UICollectionViewDataSource_Draggable> dataSource = (id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource;
        [dataSource collectionView:self.collectionView modifyDraggingItemAttributes:layoutAttributes];
    }
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *elements = [super layoutAttributesForElementsInRect:rect];
    
    UICollectionView *collectionView = self.collectionView;
    NSIndexPath *fromIndexPath = collectionView.draggableHelper.fromIndexPath;
    NSIndexPath *toIndexPath = collectionView.draggableHelper.toIndexPath;
    
    if (toIndexPath == nil) {
        if (toIndexPath == nil) {
            return elements;
        }
        for (UICollectionViewLayoutAttributes *layoutAttributes in elements) {
            if(layoutAttributes.representedElementCategory != UICollectionElementCategoryCell) {
                continue;
            }
            if ([layoutAttributes.indexPath isEqual:toIndexPath]) {
                [self modifyAttributesForFocusedItem:layoutAttributes];
            }
        }
        return elements;
    }
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in elements) {
        if(layoutAttributes.representedElementCategory != UICollectionElementCategoryCell) {
            continue;
        }
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        if ([indexPath isEqual:toIndexPath]) {
            [self modifyAttributesForFocusedItem:layoutAttributes];
        }
        if([indexPath isEqual:toIndexPath]) {
            // Item's new location
            layoutAttributes.indexPath = fromIndexPath;
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
