#import <objc/runtime.h>
#import "UICollectionView+CardLayout.h"
#import "MTCardLayoutHelper.h"

static const char * MTCardLayoutHelperKey = "MTCardLayoutHelperKey";

@implementation UICollectionView(CardLayout)

- (MTCardLayoutHelper *)cardLayoutHelper
{
    MTCardLayoutHelper *helper = objc_getAssociatedObject(self, MTCardLayoutHelperKey);
    if(helper == nil) {
        helper = [[MTCardLayoutHelper alloc] initWithCollectionView:self];
        objc_setAssociatedObject(self, MTCardLayoutHelperKey, helper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return helper;
}

- (void)cardLayoutCleanup
{
	MTCardLayoutHelper *helper = objc_getAssociatedObject(self, MTCardLayoutHelperKey);
	if (helper)
	{
		[helper unbindFromCollectionView:self];
		objc_setAssociatedObject(self, MTCardLayoutHelperKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
}

- (MTCardLayoutViewMode)viewMode
{
    return self.cardLayoutHelper.viewMode;
}

- (void)setViewMode:(MTCardLayoutViewMode)viewMode
{
    [self setViewMode:viewMode animated:NO completion:nil];
}

- (void)setViewMode:(MTCardLayoutViewMode)viewMode animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
    void (^setPresenting)() = ^{
        self.cardLayoutHelper.viewMode = viewMode;
        self.scrollEnabled = viewMode == MTCardLayoutViewModeDefault;
        
        [self.collectionViewLayout invalidateLayout];
    };

    if (animated)
    {
        [self performBatchUpdates:^{
            setPresenting();
        } completion:^(BOOL finished) {
            if (completion) completion(finished);
        }];
    }
    else
    {
        setPresenting();
        if (completion) completion(TRUE);
    }
}

- (void)deselectAndNotifyDelegate:(NSIndexPath *)indexPath
{
    [self deselectItemAtIndexPath:indexPath animated:NO];
    if ([self.delegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)]) {
        [self.delegate collectionView:self didDeselectItemAtIndexPath:indexPath];
    }
}

- (void)selectAndNotifyDelegate:(NSIndexPath *)indexPath
{
    [self selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    if ([self.delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
        [self.delegate collectionView:self didSelectItemAtIndexPath:indexPath];
    }
}

@end
