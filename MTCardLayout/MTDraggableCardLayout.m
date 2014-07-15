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
	
    if (self.collectionView.draggable != !self.presenting) {
	    self.collectionView.draggable = !self.presenting;
	}
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray * array = [super layoutAttributesForElementsInRect:rect];
    return [self.layoutHelper modifiedLayoutAttributesForElements:array];
}

- (UICollectionViewScrollDirection)scrollDirection
{
    return UICollectionViewScrollDirectionVertical;
}

@end
