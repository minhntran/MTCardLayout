#import "MTCardBackgroundView.h"
#import "UICollectionView+CardLayout.h"

@interface MTCardBackgroundView()

@property (nonatomic) UIView *contentView;

@end

@implementation MTCardBackgroundView

- (void)setContentView:(UIView *)contentView
{
    if (contentView != _contentView)
    {
        if (_contentView) [_contentView removeFromSuperview];
        
        _contentView = contentView;
        
        if (_contentView)
        {
            _contentView.frame = self.bounds;
            _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:_contentView];
        }
    }
}

- (void)didMoveToSuperview
{
    UICollectionView * collectionView = (UICollectionView *)[self superview];
    if ([collectionView isKindOfClass:[UICollectionView class]])
    {
        self.contentView = collectionView.backgroundView;
    }
}

@end
