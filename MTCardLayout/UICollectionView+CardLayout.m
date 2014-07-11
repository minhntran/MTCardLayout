#import "UICollectionView+CardLayout.h"
#import <objc/runtime.h>

static char * const MTCardLayoutBackgroundViewKey = "MTCardLayoutBackgroundView";

@implementation UICollectionView(CardLayout)

- (UIView *)backgroundView
{
    return objc_getAssociatedObject(self, MTCardLayoutBackgroundViewKey);
}

- (void)setBackgroundView:(UIView *)backgroundView
{
    objc_setAssociatedObject(self, MTCardLayoutBackgroundViewKey, backgroundView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
