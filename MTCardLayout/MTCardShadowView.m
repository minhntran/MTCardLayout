#import "MTCardShadowView.h"
#import "MTCardLayout.h"

@interface MTCardShadowView()

@property (nonatomic, strong) UITapGestureRecognizer * tapGestureRecognizer;
@property (nonatomic, strong) CAGradientLayer * gradientLayer;

@end

@implementation MTCardShadowView

- (UITapGestureRecognizer *)tapGestureRecognizer
{
	if (_tapGestureRecognizer == nil)
	{
		_tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
		[self addGestureRecognizer:_tapGestureRecognizer];
	}
	
	return _tapGestureRecognizer;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
	[super applyLayoutAttributes:layoutAttributes];
	self.tapGestureRecognizer.enabled = !layoutAttributes.hidden;
}

- (void)tapped:(id)sender
{
    UICollectionView *collectionView = (UICollectionView *)[self superview];
    if ([collectionView isKindOfClass:[UICollectionView class]])
    {
        MTCardLayout *cardLayout = (MTCardLayout *)collectionView.collectionViewLayout;
        
        if ([cardLayout isKindOfClass:[MTCardLayout class]])
        {
            [collectionView performBatchUpdates:^{
                
                NSArray *selectedIndexPaths = [collectionView indexPathsForSelectedItems];
                [selectedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath * indexPath, NSUInteger idx, BOOL *stop) {
                    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
                    if ([collectionView.delegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)])
                        [collectionView.delegate collectionView:collectionView didDeselectItemAtIndexPath:indexPath];
                }];

                [cardLayout setPresenting:NO];
            } completion:nil];
        }
    }
}

@end
