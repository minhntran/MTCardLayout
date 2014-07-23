#import "MTCollectionViewCardLayoutHelper.h"
#import "UICollectionView+CardLayout.h"
#import "UICollectionViewDataSource_Draggable.h"

#define DRAG_CURVE_LIMIT 80.0
#define DRAG_ACTION_LIMIT 150.0

static int kObservingCollectionViewOffset;

static NSString * const kContentOffsetKeyPath = @"contentOffset";

@implementation MTCollectionViewCardLayoutHelper

- (id)initWithCollectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if (self)
    {
        self.collectionView = collectionView;
        [collectionView addObserver:self
						 forKeyPath:kContentOffsetKeyPath
							options:0
							context:&kObservingCollectionViewOffset];
        
    }
    return self;
}

- (void)unbindFromCollectionView:(UICollectionView *)collectionView
{
	[collectionView removeObserver:self forKeyPath:kContentOffsetKeyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &kObservingCollectionViewOffset) {
        UICollectionView *collectionView = self.collectionView;
        if (collectionView && collectionView.dragging)
        {
            UIEdgeInsets edgeInsets = collectionView.contentInset;
            BOOL bounces = collectionView.bounces;
            
            if (collectionView.contentOffset.y < - 100 - edgeInsets.top && collectionView.scrollEnabled)
            {
                collectionView.contentInset = UIEdgeInsetsMake(-collectionView.contentOffset.y, edgeInsets.left, edgeInsets.bottom, edgeInsets.right);
                collectionView.bounces = NO;
                
                [self.collectionView setPresenting:YES animated:YES completion:^(BOOL finished) {
                    collectionView.contentInset = edgeInsets;
                    collectionView.bounces = bounces;
                }];
            }
        }
	}
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)deselect:(NSIndexPath *)indexPath
{
	[self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    if ([self.collectionView.delegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)])
        [self.collectionView.delegate collectionView:self.collectionView didDeselectItemAtIndexPath:indexPath];
}

- (void)showDeleteConfirmView:(BOOL)show animated:(BOOL)animated
{
    if (self.dragUpToDeleteConfirmView)
    {
        if (show && self.dragUpToDeleteConfirmView.superview == nil)
        {
            self.dragUpToDeleteConfirmView.center = CGPointMake(CGRectGetMidX(self.collectionView.bounds), CGRectGetMidY(self.collectionView.bounds));
            [self.collectionView addSubview:self.dragUpToDeleteConfirmView];
        }
        else if (!show && self.dragUpToDeleteConfirmView.superview != nil)
        {
            [self.dragUpToDeleteConfirmView removeFromSuperview];
        }
    }
}

- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    if ([self.collectionView.dataSource respondsToSelector:@selector(collectionView:canDeleteItemAtIndexPath:)])
    {
        canDelete = [(id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource collectionView:self.collectionView canDeleteItemAtIndexPath:indexPath];
    }
    return canDelete;
}

- (void)setPresenting:(BOOL)presenting
{
	_presenting = presenting;
	if (presenting)
	{
		if (self.tapGestureRecognizer.view == nil) [self.collectionView addGestureRecognizer:self.tapGestureRecognizer];
		if (self.panGestureRecognizer.view == nil) [self.collectionView addGestureRecognizer:self.panGestureRecognizer];
	}
	else
	{
		[self.collectionView removeGestureRecognizer:self.tapGestureRecognizer];
		[self.collectionView removeGestureRecognizer:self.panGestureRecognizer];
	}
}

#pragma mark - Tap gesture

- (UITapGestureRecognizer *)tapGestureRecognizer
{
	if (_tapGestureRecognizer == nil)
	{
		_tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
	}
	
	return _tapGestureRecognizer;
}

- (void)tapped:(id)sender
{
    if (!self.presenting) return;
    
    [self.collectionView performBatchUpdates:^{
        NSArray *selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
        [selectedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath * indexPath, NSUInteger idx, BOOL *stop) {
            [self deselect:indexPath];
        }];
        [self.collectionView setPresenting:NO];
    } completion:nil];
}

#pragma mark - Pan gesture

- (UIPanGestureRecognizer *)panGestureRecognizer
{
    if (_panGestureRecognizer == nil)
	{
		_panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
		_panGestureRecognizer.maximumNumberOfTouches = 1;
	}
    
    return _panGestureRecognizer;
}

- (void)panned:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (!self.presenting) return;
    
	UICollectionView *collectionView = self.collectionView;
    NSIndexPath *indexPath = [[collectionView indexPathsForSelectedItems] firstObject];
    if (!indexPath) return;
	
    BOOL canDelete = [self canDeleteItemAtIndexPath:indexPath];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        [self showDeleteConfirmView:canDelete animated:YES];
    }
	
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
	UICollectionViewLayoutAttributes *attributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
	CGRect originFrame = attributes.frame;
    CGPoint translation = [gestureRecognizer translationInView:[cell superview]];
    
	if (gestureRecognizer.state != UIGestureRecognizerStateCancelled)
	{
        CGFloat translatedY = translation.y;
        if (fabs(translatedY) < DRAG_ACTION_LIMIT || (!canDelete && translatedY < 0))
        {
            translatedY =  DRAG_CURVE_LIMIT * atanf(translation.y / DRAG_CURVE_LIMIT);
        }
        
		cell.frame = CGRectOffset(originFrame, 0, translatedY);
        
        if (translation.y >= DRAG_ACTION_LIMIT)
        {
            [self deselect:indexPath];
            [collectionView performBatchUpdates:nil completion:nil];
            [self showDeleteConfirmView:NO animated:NO];
            return;
        }
        else if (canDelete && self.dragUpToDeleteConfirmView)
        {
            self.dragUpToDeleteConfirmView.alpha = MAX(0.0, MIN(1.0, -translatedY/DRAG_ACTION_LIMIT));
            self.dragUpToDeleteConfirmView.highlighted = translation.y < -DRAG_ACTION_LIMIT;
        }
	}
	
	if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled)
	{
        id<UICollectionViewDataSource_Draggable> dataSource = (id<UICollectionViewDataSource_Draggable>)collectionView.dataSource;
        if (canDelete && gestureRecognizer.state != UIGestureRecognizerStateCancelled && translation.y < -DRAG_ACTION_LIMIT)
        {
            // Delete the item
            [collectionView performBatchUpdates:^{
                [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
                [dataSource collectionView:collectionView deleteItemAtIndexPath:indexPath];
                [collectionView deleteItemsAtIndexPaths:@[indexPath]];
            } completion:^(BOOL finished) {
                if ([dataSource respondsToSelector:@selector(collectionView:didDeleteItemAtIndexPath:)]) {
                    [dataSource collectionView:self.collectionView didDeleteItemAtIndexPath:indexPath];
                }
            }];
        }
        else
        {
            [UIView animateWithDuration:0.3 animations:^{
                cell.frame = originFrame;
            } completion:nil];
        }
        
        [self showDeleteConfirmView:NO animated:YES];
	}
}

@end