#import "MTCardLayout.h"
#import "UICollectionView+CardLayout.h"

@interface MTCardLayout ()

@end

@implementation MTCardLayout

- (id)init
{
    self = [super init];
    
    if (self)
    {
        [self useDefaultMetricsAndInvalidate:NO];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    
    if (self)
    {
        [self useDefaultMetricsAndInvalidate:NO];
    }
    
    return self;
}

#pragma mark - Initialization

- (void)useDefaultMetricsAndInvalidate:(BOOL)invalidate
{
    MTCardLayoutMetrics m;
    MTCardLayoutEffects e;
 
    m.insets = UIEdgeInsetsMake(20, 0, 44, 0);
    m.normalStackedHeight = 74;
	m.flexibleTopMaxHeight	= 64.0;
    m.bottomStackedHeight = 6.0;
    m.maxBottomCards = 5;
    
    e.inheritance       = 0.50;
    e.sticksTop         = YES;
    e.bouncesTop        = YES;
    
    _metrics = m;
    _effects = e;
    
    if (invalidate) [self invalidateLayout];
}

#pragma mark - Accessors

- (void)setMetrics:(MTCardLayoutMetrics)metrics
{
    _metrics = metrics;
    
    [self invalidateLayout];
}

- (void)setEffects:(MTCardLayoutEffects)effects
{
    _effects = effects;
    
    [self invalidateLayout];
}

#pragma mark - Layout

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath selectedIndexPath:(NSIndexPath *)selectedIndexPath numberOfItems:(NSInteger)numberOfItems
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
	attributes.zIndex = indexPath.item + 1;
	
	if (self.collectionView.presenting)
	{
		if (selectedIndexPath && [selectedIndexPath isEqual:indexPath])
		{
			// Layout selected cell (normal size)
			attributes.frame = frameForSelectedCard(self.collectionView.bounds, _metrics);
		}
		else
		{
			// Layout unselected cell (bottom-stuck)
			attributes.frame = frameForUnselectedCard(indexPath, selectedIndexPath, self.collectionView.bounds, _metrics);
		}
	}
	else // stack mode
	{
		// Layout collapsed cells (collapsed size)
		BOOL isLast = (indexPath.item == (numberOfItems - 1));
		attributes.frame = frameForCardAtIndex(indexPath, isLast, self.collectionView.bounds, _metrics, _effects);
	}
	
	attributes.hidden = attributes.frame.size.height == 0;

    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:indexPath.section];
	NSArray *selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
	return [self layoutAttributesForItemAtIndexPath:indexPath selectedIndexPath:[selectedIndexPaths firstObject] numberOfItems:numberOfItems];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    CGRect effectiveBounds = self.collectionView.bounds;
    effectiveBounds.origin.y += _metrics.insets.top;
    effectiveBounds.size.height -= _metrics.insets.top + _metrics.insets.bottom;
	rect = CGRectIntersection(rect, effectiveBounds);
    
    NSRange range = rangeForVisibleCells(rect, [self.collectionView numberOfItemsInSection:0] , _metrics);
    
    NSMutableArray *cells = [NSMutableArray arrayWithCapacity:range.length + 2];
    
	NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
	NSIndexPath *selectedIndexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];

    for (NSUInteger item=range.location; item < (range.location + range.length); item++)
    {
        [cells addObject:[self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] selectedIndexPath:selectedIndexPath numberOfItems:numberOfItems]];
    }
    
    // selected item is out of range
    if (self.collectionView.presenting && selectedIndexPath && (selectedIndexPath.item < range.location || selectedIndexPath.item >= range.location + range.length))
    {
        [cells addObject:[self layoutAttributesForItemAtIndexPath:selectedIndexPath selectedIndexPath:selectedIndexPath numberOfItems:numberOfItems]];
    }
	
    return cells;
}

//- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
//{
//    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:itemIndexPath];
//    
//    CGRect bounds = self.collectionView.bounds;
//    attributes.frame = CGRectMake(0, bounds.origin.y, self.metrics.normal.size.width, self.metrics.normal.size.height);
//    
//    return attributes;
//}

- (CGSize)collectionViewContentSize
{
    return collectionViewSize(self.collectionView.bounds, [self.collectionView numberOfItemsInSection:0], _metrics);
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

#pragma mark - Postioning

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGPoint targetContentOffset = proposedContentOffset;
    
    if (self.collectionView.scrollEnabled)
    {
        CGFloat flexibleHeight = self.metrics.flexibleTopMaxHeight - self.metrics.insets.top;
        if (targetContentOffset.y < flexibleHeight) {
            targetContentOffset.y = (targetContentOffset.y < flexibleHeight / 2) ? 0.0 : flexibleHeight;
        } else {
            if (self.metrics.normalStackedHeight > 0) {
                targetContentOffset.y = roundf((targetContentOffset.y - flexibleHeight) / self.metrics.normalStackedHeight) * self.metrics.normalStackedHeight + flexibleHeight;
            }
        }
    }
    
    return targetContentOffset;
}

#pragma mark Cell visibility

NSRange rangeForVisibleCells(CGRect rect, NSInteger count, MTCardLayoutMetrics m)
{
	rect.origin.y -= m.flexibleTopMaxHeight;
    NSInteger min = (m.normalStackedHeight == 0) ? 0 : floor(rect.origin.y / m.normalStackedHeight);
    NSInteger max = (m.normalStackedHeight == 0) ? count : ceil((rect.origin.y + rect.size.height) / m.normalStackedHeight);
    
    max = (max > count) ? count : max;
    
    min = (min < 0)     ? 0   : min;
    min = (min < max)   ? min : max;
    
    NSRange r = NSMakeRange(min, max-min);
    
    return r;
}

CGSize collectionViewSize(CGRect bounds, NSInteger count, MTCardLayoutMetrics m)
{
	CGFloat height = count * m.normalStackedHeight + m.flexibleTopMaxHeight - m.insets.top + fmodf(bounds.size.height, m.normalStackedHeight);
    return CGSizeMake(bounds.size.width, height);
}

#pragma mark Cell positioning

/// Normal collapsed cell, with bouncy animations on top
CGRect frameForCardAtIndex(NSIndexPath *indexPath, BOOL isLastCell, CGRect b, MTCardLayoutMetrics m, MTCardLayoutEffects e)
{
    CGRect f = UIEdgeInsetsInsetRect(b, m.insets);

    f.origin.y = indexPath.item * m.normalStackedHeight + m.flexibleTopMaxHeight;
    
    if (b.origin.y < 0 && e.inheritance > 0.0 && e.bouncesTop)
    {
        // Bouncy effect on top (works only on constant invalidation)
        if (indexPath.section == 0 && indexPath.item == 0)
        {
            // Keep stuck at top
            f.origin.y      = b.origin.y * e.inheritance/2.0 + m.flexibleTopMaxHeight;
        }
        else
        {
            // Displace in stepping amounts factored by resitatnce
            f.origin.y     -= b.origin.y * indexPath.item * e.inheritance;
        }
    }
    else if (b.origin.y > 0)
    {
        // Stick to top
        if (f.origin.y < b.origin.y + m.insets.top && e.sticksTop)
        {
            f.origin.y = b.origin.y + m.insets.top;
        }
    }
    
    // Edge case, if it's the last cell, display in full height, to avoid any issues.
    if (!isLastCell)
    {
        f.size.height = m.normalStackedHeight * 2;
    }
    
    return f;
}

CGRect frameForSelectedCard(CGRect b, MTCardLayoutMetrics m)
{
    return UIEdgeInsetsInsetRect(b, m.insets);
}

/// Bottom-stack card
CGRect frameForUnselectedCard(NSIndexPath *indexPath, NSIndexPath *indexPathSelected, CGRect b, MTCardLayoutMetrics m)
{
    NSInteger firstVisibleItem = ceil((b.origin.y - m.flexibleTopMaxHeight) / m.normalStackedHeight);
    if (firstVisibleItem < 0) firstVisibleItem = 0;

    NSInteger itemOrder = indexPath.item - firstVisibleItem;
    if (indexPathSelected && indexPath.item > indexPathSelected.item) itemOrder--;
	
    CGFloat bottomStackedTotalHeight = m.bottomStackedHeight * m.maxBottomCards;
    
    CGRect f = UIEdgeInsetsInsetRect(b, m.insets);
    f.origin.y = b.origin.y + b.size.height + m.bottomStackedHeight * itemOrder - bottomStackedTotalHeight;
    if  (indexPath.item < firstVisibleItem)
    {
        f.size.height = 0;
    }
 
    f = CGRectInset(f, (bottomStackedTotalHeight / m.bottomStackedHeight - itemOrder - 1) * 2.0, 0);
    
    return f;
}

@end
