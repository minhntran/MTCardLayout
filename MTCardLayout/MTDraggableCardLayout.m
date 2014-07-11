#import "MTDraggableCardLayout.h"
#import "LSCollectionViewLayoutHelper.h"
#import "UICollectionView+Draggable.h"

@interface MTDraggableCardLayout ()
{
    LSCollectionViewLayoutHelper *_layoutHelper;
}
@end

@implementation MTDraggableCardLayout

- (LSCollectionViewLayoutHelper *)layoutHelper
{
    if(_layoutHelper == nil) {
        _layoutHelper = [[LSCollectionViewLayoutHelper alloc] initWithCollectionViewLayout:self];
    }
    return _layoutHelper;
}

- (void)prepareLayout
{
    [super prepareLayout];
    
    self.collectionView.draggable = !self.presenting;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray * array = [super layoutAttributesForElementsInRect:rect];
    if (self.collectionView.movingCell)
    {
        [array enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attributes, NSUInteger idx, BOOL *stop) {
            if (attributes.representedElementCategory == UICollectionElementCategoryCell)
            {
                CGRect frame = attributes.frame;
                frame.size.height -= self.metrics.collapsed.overlap;
                attributes.frame = frame;
            }
        }];
    }
    return [self.layoutHelper modifiedLayoutAttributesForElements:array];
}

- (UICollectionViewScrollDirection)scrollDirection
{
    return UICollectionViewScrollDirectionVertical;
}

@end
