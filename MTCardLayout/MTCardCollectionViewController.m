#import "MTCardCollectionViewController.h"
#import "MTCardLayout.h"

#define PAN_LIMIT 64.0

@interface MTCardCollectionViewController ()

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic) CGPoint panGestureStartLocation;

@end

@implementation MTCardCollectionViewController

- (MTCardLayout *)cardLayout
{
	return (MTCardLayout *)self.collectionViewLayout;
}

- (void)setPresenting:(BOOL)presenting animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
	if (!presenting)
	{
		NSArray *selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
		[selectedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath * indexPath, NSUInteger idx, BOOL *stop) {
			[self deselectIndexPath:indexPath updateLayout:NO];
		}];
	}

	if (animated)
	{
		[self.collectionView performBatchUpdates:^{
			self.cardLayout.presenting = presenting;
		} completion:completion];
	}
	else
	{
		self.cardLayout.presenting = YES;
	}
}

- (void)deselectIndexPath:(NSIndexPath *)indexPath updateLayout:(BOOL)updateLayout
{
	[self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
	[self collectionView:self.collectionView didDeselectItemAtIndexPath:indexPath];
	
	if (updateLayout)
	{
		[self.collectionView performBatchUpdates:nil completion:nil];
	}
}

#pragma mark - Dynamics

- (void)addPanGesture:(UICollectionViewCell *)cell
{
	if (self.panGestureRecognizer == nil)
	{
		self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandler:)];
		self.panGestureRecognizer.maximumNumberOfTouches = 1;
	}

	[cell addGestureRecognizer:self.panGestureRecognizer];
}

- (void)panHandler:(UIPanGestureRecognizer *)gestureRecognizer
{
	UICollectionViewCell *cell = (UICollectionViewCell *)gestureRecognizer.view;
	NSIndexPath * indexPath = [self.collectionView indexPathForCell:cell];
	UICollectionViewLayoutAttributes *attributes = [self.cardLayout layoutAttributesForItemAtIndexPath:indexPath];
	CGRect originFrame = attributes.frame;

	if (gestureRecognizer.state != UIGestureRecognizerStateCancelled)
	{
		CGPoint translation = [gestureRecognizer translationInView:[cell superview]];
		CGFloat translatedY = PAN_LIMIT * atanf(translation.y / PAN_LIMIT);
		cell.frame = CGRectOffset(originFrame, 0, translatedY);
		
		if (translatedY > PAN_LIMIT)
		{
			[self deselectIndexPath:indexPath updateLayout:YES];
			return;
		}
        else if (translatedY < -PAN_LIMIT)
        {
            [self setPresenting:NO animated:YES completion:nil];
            return;
        }
	}
	
	if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled)
	{
		[UIView animateWithDuration:0.3 animations:^{
			cell.frame = originFrame;
		} completion:nil];
	}
}

- (void)removePanGesture
{
	if (self.panGestureRecognizer && self.panGestureRecognizer.view)
	{
		[self.panGestureRecognizer.view removeGestureRecognizer:self.panGestureRecognizer];
	}
}

#pragma mark - UICollectionView datasource/delegate

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
	[self removePanGesture];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if (cell)
    {
        [self addPanGesture:cell];
    }

	[self setPresenting:YES animated:YES completion:nil];
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.dragging)
    {
        UIEdgeInsets edgeInsets = scrollView.contentInset;
        BOOL bounces = scrollView.bounces;
        
        if (scrollView == self.collectionView && scrollView.contentOffset.y < - PAN_LIMIT - edgeInsets.top && scrollView.scrollEnabled)
        {
            scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, edgeInsets.left, edgeInsets.bottom, edgeInsets.right);
            scrollView.bounces = NO;
            
            [self setPresenting:YES animated:YES completion:^(BOOL finished) {
                scrollView.contentInset = edgeInsets;
                scrollView.bounces = bounces;
            }];
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
	if (scrollView == self.collectionView && scrollView.scrollEnabled)
	{
		[self.cardLayout calcTargetScrollOffset:targetContentOffset];
	}
}

@end
