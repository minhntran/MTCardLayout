#import <objc/runtime.h>
#import "UICollectionView+CardLayout.h"
#import "MTCollectionViewCardLayoutHelper.h"

static const char * MTCollectionViewCardLayoutHelperKey = "UICollectionViewCardLayoutHelper";

@implementation UICollectionView(CardLayout)

- (MTCollectionViewCardLayoutHelper *)getCardLayoutHelper
{
    MTCollectionViewCardLayoutHelper *helper = objc_getAssociatedObject(self, MTCollectionViewCardLayoutHelperKey);
    if(helper == nil) {
        helper = [[MTCollectionViewCardLayoutHelper alloc] initWithCollectionView:self];
        objc_setAssociatedObject(self, MTCollectionViewCardLayoutHelperKey, helper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return helper;
}

- (void)cardLayoutCleanup
{
	MTCollectionViewCardLayoutHelper *helper = objc_getAssociatedObject(self, MTCollectionViewCardLayoutHelperKey);
	if (helper)
	{
		[helper unbindFromCollectionView:self];
		objc_setAssociatedObject(self, MTCollectionViewCardLayoutHelperKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
}

- (void)correctCellZIndexes
{
    NSArray * visibleIndexPaths = [[self indexPathsForVisibleItems] sortedArrayUsingSelector:@selector(compare:)];
    for (NSInteger i = visibleIndexPaths.count - 1; i >=0; i--)
    {
        NSIndexPath *visibleIndexPath = visibleIndexPaths[i];
        UICollectionViewCell *cell = [self cellForItemAtIndexPath:visibleIndexPath];
        [self sendSubviewToBack:cell];
    }
}

- (UIImageView *)dragUpToDeleteConfirmView
{
    return [self getCardLayoutHelper].dragUpToDeleteConfirmView;
}

- (void)setDragUpToDeleteConfirmView:(UIImageView *)dragUpToDeleteConfirmView
{
    [[self getCardLayoutHelper] setDragUpToDeleteConfirmView:dragUpToDeleteConfirmView];
}

- (BOOL)presenting
{
    return [self getCardLayoutHelper].presenting;
}

- (void)setPresenting:(BOOL)presenting
{
    [self setPresenting:presenting animated:NO completion:nil];
}

- (void)setPresenting:(BOOL)presenting animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
    void (^setPresenting)() = ^{
        [self getCardLayoutHelper].presenting = presenting;
        self.scrollEnabled = !presenting;
        
        [self.collectionViewLayout invalidateLayout];
    };

    if (animated)
    {
        [self performBatchUpdates:^{
            setPresenting();
        } completion:^(BOOL finished) {
            if (completion) completion(finished);
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self correctCellZIndexes];
//            });
        }];
    }
    else
    {
        setPresenting();
        if (completion) completion(TRUE);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self correctCellZIndexes];
//        });
    }
}

- (UITapGestureRecognizer *)cardLayoutTapGestureRecognizer
{
	return [self getCardLayoutHelper].tapGestureRecognizer;
}

- (UIPanGestureRecognizer *)cardLayoutPanGestureRecognizer
{
	return [self getCardLayoutHelper].panGestureRecognizer;
}

@end
