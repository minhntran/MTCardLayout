#import "MTCardLayout.h"
#import "MTCardShadowView.h"

NSString * const MTCollectionElementKindShadowView = @"MTCollectionElementKindShadowView";

@interface MTCardLayout ()
{
}
@end

@implementation MTCardLayout

- (id)init
{
    self = [super init];
    if (self)
    {
        [self registerReusableViews];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self registerReusableViews];
    }
    return self;
}

- (void)registerReusableViews
{
    [self registerClass:[MTCardShadowView class] forDecorationViewOfKind:MTCollectionElementKindShadowView];
}

#pragma mark - Initialization

+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        size = CGSizeMake(size.height, size.width);
    }
    return size;
}

- (void)useDefaultMetricsAndInvalidate:(BOOL)invalidate
{
    UIApplication *application = [UIApplication sharedApplication];
    CGSize screenSize =  [MTCardLayout sizeInOrientation:application.statusBarOrientation];

    MTCardLayoutMetrics m;
    MTCardLayoutEffects e;
 
	m.flexibleTopMaxHeight	= 64.0;
	m.flexibleTopMinHeight	= 20.0;

    m.normal.size       = CGSizeMake(screenSize.width, screenSize.height - 64);
    m.normal.overlap    = 0.0;
    
	m.collapsed.size    = m.normal.size; // CGSizeMake(screenSize.width, 150.0);
    m.collapsed.overlap = m.collapsed.size.height - 74.0;
    
    m.bottomStackedHeight = 6.0;
    m.bottomStackedTotalHeight = m.bottomStackedHeight * 5;
    
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

- (void)setPresenting:(BOOL)presenting
{
	_presenting = presenting;
    self.collectionView.scrollEnabled = !presenting;

	[self invalidateLayout];
}

#pragma mark - Layout

- (void)prepareLayout
{
    [super prepareLayout];
    
    [self useDefaultMetricsAndInvalidate:NO];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath selectedIndexPath:(NSIndexPath *)selectedIndexPath numberOfItems:(NSInteger)numberOfItems
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
	attributes.zIndex = indexPath.item + 1;
	
	if (self.presenting)
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

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:kind withIndexPath:indexPath];

	if (kind == MTCollectionElementKindShadowView)
	{
		attributes.zIndex = INT_MAX - 1;
        attributes.frame = frameForBottomShadow(self.collectionView.bounds, _metrics);
		attributes.hidden = !self.presenting;
		if (attributes.hidden)
		{
            attributes.frame = self.collectionView.bounds;
			attributes.alpha = 0.0;
		}
		else
		{
			attributes.alpha = 1.0;
		}
	}

	return attributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
//    CGRect effectiveBounds = self.collectionView.bounds;
//    effectiveBounds.origin.y += _metrics.flexibleTopMinHeight;
//    effectiveBounds.size.height -= _metrics.flexibleTopMinHeight;
//	rect = CGRectIntersection(rect, effectiveBounds);
//    
    NSRange range = rangeForVisibleCells(rect, [self.collectionView numberOfItemsInSection:0] , _metrics);
    
    // Uncomment to see the current range
//    NSLog(@"Visible range: %@", NSStringFromRange(range));
    
    NSMutableArray *cells = [NSMutableArray arrayWithCapacity:range.length + 2];
    
	NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
	NSIndexPath *selectedIndexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];

    for (NSUInteger item=range.location; item < (range.location + range.length); item++)
    {
        [cells addObject:[self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] selectedIndexPath:selectedIndexPath numberOfItems:numberOfItems]];
    }
    
    // selected item is out of range
    if (self.presenting && selectedIndexPath && (selectedIndexPath.item < range.location || selectedIndexPath.item >= range.location + range.length))
    {
        [cells addObject:[self layoutAttributesForItemAtIndexPath:selectedIndexPath selectedIndexPath:selectedIndexPath numberOfItems:numberOfItems]];
    }
	
	if (self.presenting)
	{
		[cells addObject:[self layoutAttributesForDecorationViewOfKind:MTCollectionElementKindShadowView atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]];
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
        CGFloat flexibleHeight = self.metrics.flexibleTopMaxHeight - self.metrics.flexibleTopMinHeight;
        if (targetContentOffset.y < flexibleHeight) {
            targetContentOffset.y = (targetContentOffset.y < flexibleHeight / 2) ? 0.0 : flexibleHeight;
        } else {
            CGFloat cellHeight = self.metrics.collapsed.size.height - self.metrics.collapsed.overlap;
            if (cellHeight > 0) {
                targetContentOffset.y = roundf((targetContentOffset.y - flexibleHeight) / cellHeight) * cellHeight + flexibleHeight;
            }
        }
    }
    
    return targetContentOffset;
}

#pragma mark Cell visibility

NSRange rangeForVisibleCells(CGRect rect, NSInteger count, MTCardLayoutMetrics m)
{
	rect.origin.y -= m.flexibleTopMaxHeight;
    NSInteger min = floor(rect.origin.y / (m.collapsed.size.height - m.collapsed.overlap));
    NSInteger max = ceil((rect.origin.y + rect.size.height) / (m.collapsed.size.height - m.collapsed.overlap));
    
    max = (max > count) ? count : max;
    
    min = (min < 0)     ? 0   : min;
    min = (min < max)   ? min : max;
    
    NSRange r = NSMakeRange(min, max-min);
    
    return r;
}

CGSize collectionViewSize(CGRect bounds, NSInteger count, MTCardLayoutMetrics m)
{
	CGFloat stepHeight = m.collapsed.size.height - m.collapsed.overlap;
	CGFloat height = count * (m.collapsed.size.height - m.collapsed.overlap) + m.flexibleTopMaxHeight - m.flexibleTopMinHeight + fmodf(bounds.size.height, stepHeight);
    return CGSizeMake(bounds.size.width, height);
}

#pragma mark Cell positioning

/// Normal collapsed cell, with bouncy animations on top
CGRect frameForCardAtIndex(NSIndexPath *indexPath, BOOL isLastCell, CGRect b, MTCardLayoutMetrics m, MTCardLayoutEffects e)
{
    CGRect f;
    
    f.origin.x = (b.size.width - m.normal.size.width) / 2.0;
    f.origin.y = indexPath.item * (m.collapsed.size.height - m.collapsed.overlap) + m.flexibleTopMaxHeight;
    
    // The default size is the normal size
    f.size = m.collapsed.size;
    
    if (b.origin.y < 0 && e.inheritance > 0.0 && e.bouncesTop)
    {
        // Bouncy effect on top (works only on constant invalidation)
        if (indexPath.section == 0 && indexPath.item == 0)
        {
            // Keep stuck at top
            f.origin.y      = b.origin.y * e.inheritance/2.0 + m.flexibleTopMaxHeight;
            f.size.height   = m.collapsed.size.height - b.origin.y * (1 + e.inheritance);
        }
        else
        {
            // Displace in stepping amounts factored by resitatnce
            f.origin.y     -= b.origin.y * indexPath.item * e.inheritance;
            f.size.height  -= b.origin.y * e.inheritance;
        }
    }
    else if (b.origin.y > 0)
    {
        // Stick to top
        if (f.origin.y < b.origin.y + m.flexibleTopMinHeight && e.sticksTop)
        {
            f.origin.y = b.origin.y + m.flexibleTopMinHeight;
        }
    }
    
    // Edge case, if it's the last cell, display in full height, to avoid any issues.
    if (isLastCell)
    {
        f.size = m.normal.size;
    }
    
//    NSLog(@"Frame for row: %ld: %@", indexPath.row, NSStringFromCGRect(f));
    
    return f;
}

CGRect frameForSelectedCard(CGRect b, MTCardLayoutMetrics m)
{
    CGRect f;
    
    f.size      = m.normal.size;
    f.origin.x  = (b.size.width  - f.size.width ) / 2.0;
    f.origin.y  = b.origin.y + m.flexibleTopMinHeight;
    
    return f;
}

/// Bottom-stack card
CGRect frameForUnselectedCard(NSIndexPath *indexPath, NSIndexPath *indexPathSelected, CGRect b, MTCardLayoutMetrics m)
{
    NSInteger firstVisibleItem = ceil((b.origin.y - m.flexibleTopMaxHeight) / (m.collapsed.size.height - m.collapsed.overlap));
    if (firstVisibleItem < 0) firstVisibleItem = 0;

    NSInteger itemOrder = indexPath.item - firstVisibleItem;
    if (indexPathSelected && indexPath.item > indexPathSelected.item) itemOrder--;
	
    CGRect f;
    f.size        = m.collapsed.size;
    f.origin.x    = (b.size.width - m.normal.size.width) / 2.0;
    f.origin.y = b.origin.y + b.size.height + m.bottomStackedHeight * itemOrder  - m.bottomStackedTotalHeight;
    if  (indexPath.item < firstVisibleItem)
    {
        f.size.height = 0;
    }
 
    f = CGRectInset(f, (m.bottomStackedTotalHeight / m.bottomStackedHeight - itemOrder - 1) * 2.0, 0);
    
//	f.size.width = MIN(b.size.width, f.size.width);
//	f.origin.y = MIN(b.origin.y + b.size.height - 10, f.origin.y);
	
    return f;
}

CGRect frameForBottomShadow(CGRect b, MTCardLayoutMetrics m)
{
	CGRect f;
    
    f.size.width  = b.size.width;
	f.size.height = b.size.height - m.flexibleTopMinHeight - m.normal.size.height;
    f.origin.x  = 0;
    f.origin.y  = b.origin.y + m.flexibleTopMinHeight + m.normal.size.height;
    
    return f;
}

@end
