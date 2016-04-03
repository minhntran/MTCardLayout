#import <objc/runtime.h>
#import "MTDraggableHelper.h"

static const char * MTDraggableHelperKey = "MTDraggableHelperKey";

@implementation UICollectionView (DraggableCardLayout)

- (MTDraggableHelper *)draggableHelper
{
    MTDraggableHelper *helper = objc_getAssociatedObject(self, MTDraggableHelperKey);
    if(helper == nil) {
        helper = [[MTDraggableHelper alloc] initWithCollectionView:self];
        objc_setAssociatedObject(self, MTDraggableHelperKey, helper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return helper;
}

@end
