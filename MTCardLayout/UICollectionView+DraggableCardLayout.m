#import <objc/runtime.h>
#import "MTDraggableCardLayoutHelper.h"

static const char MTDraggableCardLayoutHelperKey;

@implementation UICollectionView (DraggableCardLayout)

- (MTDraggableCardLayoutHelper *)draggableCardLayoutHelper
{
    MTDraggableCardLayoutHelper *helper = objc_getAssociatedObject(self, &MTDraggableCardLayoutHelperKey);
    if(helper == nil) {
        helper = [[MTDraggableCardLayoutHelper alloc] initWithCollectionView:self];
        objc_setAssociatedObject(self, &MTDraggableCardLayoutHelperKey, helper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return helper;
}

@end
