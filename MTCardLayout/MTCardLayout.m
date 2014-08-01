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

- (void)dealloc
{
	[self.collectionView cardLayoutCleanup];
}

#pragma mark - Initialization

- (void)useDefaultMetricsAndInvalidate:(BOOL)invalidate
{
    MTCardLayoutMetrics m;
    MTCardLayoutEffects e;
 
    m.presentingInsets = UIEdgeInsetsMake(00, 0, 44, 0);
    m.listingInsets = UIEdgeInsetsMake(20.0, 0, 0, 0);
    m.minimumVisibleHeight = 74;
	m.flexibleTop = 0.0;
    m.stackedVisibleHeight = 6.0;
    m.maxStackedCards = 5;

    e.inheritance       = 0.50;
    e.sticksTop         = YES;
    e.bouncesTop        = YES;
    e.spreading         = NO;
    
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

- (void)prepareLayout
{
	_metrics.visibleHeight = _metrics.minimumVisibleHeight;
    if (_effects.spreading)
    {
        NSInteger numberOfCards = [self.collectionView numberOfItemsInSection:0];
        if (numberOfCards > 0)
        {
            CGFloat height = (self.collectionView.frame.size.height - self.collectionView.contentInset.top - _metrics.listingInsets.top - _metrics.flexibleTop) / numberOfCards;
            if (height > _metrics.visibleHeight) _metrics.visibleHeight = height;
        }
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath selectedIndexPath:(NSIndexPath *)selectedIndexPath numberOfItems:(NSInteger)numberOfItems
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
	attributes.zIndex = indexPath.item + 1;
//    attributes.transform3D = CATransform3DMakeTranslation(0, 0, attributes.zIndex);
	
	if (self.collectionView.presenting)
	{
		if (selectedIndexPath && [selectedIndexPath isEqual:indexPath])
		{
			// Layout selected cell (normal size)
			attributes.frame = frameForSelectedCard(self.collectionView.bounds, self.collectionView.contentInset, _metrics);
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
		attributes.frame = frameForCardAtIndex(indexPath, isLast, self.collectionView.bounds, self.collectionView.contentInset, _metrics, _effects);
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
    effectiveBounds.origin.y += self.collectionView.contentInset.top;
    effectiveBounds.origin.y += _metrics.listingInsets.top;
    effectiveBounds.size.height -= _metrics.listingInsets.top + _metrics.listingInsets.bottom;
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

- (CGSize)collectionViewContentSize
{
    return collectionViewSize(self.collectionView.bounds, self.collectionView.contentInset, [self.collectionView numberOfItemsInSection:0], _metrics);
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
		targetContentOffset.y += self.collectionView.contentInset.top;
        CGFloat flexibleHeight = _metrics.flexibleTop;
        if (targetContentOffset.y < flexibleHeight) {
            targetContentOffset.y = (targetContentOffset.y < flexibleHeight / 2) ? 0.0 : flexibleHeight;
        } else {
            if (_metrics.visibleHeight > 0) {
                targetContentOffset.y = roundf((targetContentOffset.y - flexibleHeight) / _metrics.visibleHeight) * _metrics.visibleHeight + flexibleHeight;
            }
        }
		targetContentOffset.y -= self.collectionView.contentInset.top;
    }
    

    return targetContentOffset;
}

#pragma mark Cell visibility

NSRange rangeForVisibleCells(CGRect rect, NSInteger count, MTCardLayoutMetrics m)
{
	rect.origin.y -= m.flexibleTop + m.listingInsets.top;
    NSInteger min = (m.visibleHeight == 0) ? 0 : floor(rect.origin.y / m.visibleHeight);
    NSInteger max = (m.visibleHeight == 0) ? count : ceil((rect.origin.y + rect.size.height) / m.visibleHeight);
    
    max = (max > count) ? count : max;
    
    min = (min < 0)     ? 0   : min;
    min = (min < max)   ? min : max;
    
    NSRange r = NSMakeRange(min, max-min);
    
    return r;
}

CGSize collectionViewSize(CGRect bounds, UIEdgeInsets contentInset, NSInteger count, MTCardLayoutMetrics m)
{
	CGFloat height = count * m.visibleHeight + m.flexibleTop + m.listingInsets.top + fmodf(bounds.size.height - contentInset.top - m.listingInsets.top, m.visibleHeight);
    return CGSizeMake(bounds.size.width, height);
}

#pragma mark Cell positioning

/// Normal collapsed cell, with bouncy animations on top
CGRect frameForCardAtIndex(NSIndexPath *indexPath, BOOL isLastCell, CGRect b, UIEdgeInsets contentInset, MTCardLayoutMetrics m, MTCardLayoutEffects e)
{
    CGRect f = UIEdgeInsetsInsetRect(UIEdgeInsetsInsetRect(b, contentInset), m.listingInsets);
    f.size.height -= m.flexibleTop;

    f.origin.y = indexPath.item * m.visibleHeight + m.flexibleTop + m.listingInsets.top;
    
    if (b.origin.y + contentInset.top < 0 && e.inheritance > 0.0 && e.bouncesTop)
    {
        // Bouncy effect on top (works only on constant invalidation)
        if (indexPath.section == 0 && indexPath.item == 0)
        {
            // Keep stuck at top
            f.origin.y      = (b.origin.y + contentInset.top) * e.inheritance/2.0 + m.flexibleTop + m.listingInsets.top;
        }
        else
        {
            // Displace in stepping amounts factored by resitatnce
            f.origin.y     -= (b.origin.y + contentInset.top) * indexPath.item * e.inheritance;
        }
    }
    else if (b.origin.y + contentInset.top > 0)
    {
        // Stick to top
        if (f.origin.y < b.origin.y + contentInset.top + m.listingInsets.top && e.sticksTop)
        {
            f.origin.y = b.origin.y + contentInset.top + m.listingInsets.top;
        }
    }
    
    // Edge case, if it's the last cell, display in full height, to avoid any issues.
//    if (!isLastCell)
//    {
//        f.size.height = m.visibleHeight * 2;
//    }
    
    return f;
}

CGRect frameForSelectedCard(CGRect b, UIEdgeInsets contentInset, MTCardLayoutMetrics m)
{
    return UIEdgeInsetsInsetRect(UIEdgeInsetsInsetRect(b, contentInset), m.presentingInsets);
}

/// Bottom-stack card
CGRect frameForUnselectedCard(NSIndexPath *indexPath, NSIndexPath *indexPathSelected, CGRect b, MTCardLayoutMetrics m)
{
    NSInteger firstVisibleItem = ceil((b.origin.y - m.flexibleTop - m.listingInsets.top) / m.visibleHeight);
    if (firstVisibleItem < 0) firstVisibleItem = 0;

    NSInteger itemOrder = indexPath.item - firstVisibleItem;
    if (indexPathSelected && indexPath.item > indexPathSelected.item) itemOrder--;
	
    CGFloat bottomStackedTotalHeight = m.stackedVisibleHeight * m.maxStackedCards;
    
    CGRect f = UIEdgeInsetsInsetRect(b, m.presentingInsets);
    f.origin.y = b.origin.y + b.size.height + m.stackedVisibleHeight * itemOrder - bottomStackedTotalHeight;
    if  (indexPath.item < firstVisibleItem)
    {
        f.size.height = 0;
    }
 
    f = CGRectInset(f, (bottomStackedTotalHeight / m.stackedVisibleHeight - itemOrder - 1) * 2.0, 0);
    
    return f;
}

@end
