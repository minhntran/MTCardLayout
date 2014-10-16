//
//  Copyright (c) 2013 Luke Scott
//  https://github.com/lukescott/DraggableCollectionView
//  Distributed under MIT license
//

#import "UICollectionView+Draggable.h"
#import "LSCollectionViewHelper.h"
#import <objc/runtime.h>

static const char * LSCollectionViewHelperObjectKey = "LSCollectionViewHelper";

@implementation UICollectionView (Draggable)

- (void)draggableCleanup
{
    LSCollectionViewHelper *helper = objc_getAssociatedObject(self, LSCollectionViewHelperObjectKey);
    if(helper != nil) {
		[helper unbindFromCollectionView:self];
		objc_setAssociatedObject(self, LSCollectionViewHelperObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
}

- (LSCollectionViewHelper *)getHelper
{
    LSCollectionViewHelper *helper = objc_getAssociatedObject(self, LSCollectionViewHelperObjectKey);
    if(helper == nil) {
        helper = [[LSCollectionViewHelper alloc] initWithCollectionView:self];
        objc_setAssociatedObject(self, LSCollectionViewHelperObjectKey, helper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return helper;
}

- (BOOL)draggable
{
    return [self getHelper].enabled;
}

- (void)setDraggable:(BOOL)draggable
{
    [self getHelper].enabled = draggable;
}

- (UIEdgeInsets)scrollingEdgeInsets
{
    return [self getHelper].scrollingEdgeInsets;
}

- (void)setScrollingEdgeInsets:(UIEdgeInsets)scrollingEdgeInsets
{
    [self getHelper].scrollingEdgeInsets = scrollingEdgeInsets;
}

- (CGFloat)scrollingSpeed
{
    return [self getHelper].scrollingSpeed;
}

- (void)setScrollingSpeed:(CGFloat)scrollingSpeed
{
    [self getHelper].scrollingSpeed = scrollingSpeed;
}

- (NSIndexPath *)indexPathForMovingItem
{
    return [self getHelper].indexPathForMovingItem;
}

- (UIImageView *)dropOnToDeleteView
{
	return [self getHelper].dropOnToDeleteView;
}

- (void)setDropOnToDeleteView:(UIImageView *)dropOnToDeleteView
{
	[[self getHelper] setDropOnToDeleteView:dropOnToDeleteView];
}

@end
