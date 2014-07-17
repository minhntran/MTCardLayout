#import "MTDraggableCardLayout.h"
#import "UICollectionView+CardLayout.h"
#import "LSCollectionViewLayoutHelper.h"
#import "UICollectionView+Draggable.h"

@interface MTDraggableCardLayout () <UICollectionViewLayout_Warpable>

@property (strong, nonatomic) LSCollectionViewLayoutHelper *layoutHelper;

@end

@implementation MTDraggableCardLayout

- (void)dealloc
{
	[self.collectionView draggableCleanup];
}

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
	
    if (self.collectionView.draggable != !self.collectionView.presenting) {
	    self.collectionView.draggable = !self.collectionView.presenting;
	}
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [self.layoutHelper modifiedLayoutAttributesForElements:[super layoutAttributesForElementsInRect:rect]];
}

- (UICollectionViewScrollDirection)scrollDirection
{
    return UICollectionViewScrollDirectionVertical;
}

@end
