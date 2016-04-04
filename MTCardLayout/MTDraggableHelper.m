#import "MTDraggableHelper.h"
#import "MTCommonTypes.h"
#import "UICollectionView+CardLayout.h"
#import "UICollectionView+DraggableCardLayout.h"

#define SCROLLING_SPEED 300.f
#define SCROLLING_EDGE_INSET 50.f

#define DRAG_CURVE_LIMIT 120.0
#define DRAG_ACTION_LIMIT 150.0

#ifndef CGGEOMETRY__SUPPORT_H_
CG_INLINE CGPoint
_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}
#endif

typedef NS_ENUM(NSInteger, _ScrollingDirection) {
    _ScrollingDirectionUnknown = 0,
    _ScrollingDirectionUp,
    _ScrollingDirectionDown,
    _ScrollingDirectionLeft,
    _ScrollingDirectionRight
};

@interface MTDraggableHelper() <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UICollectionView *collectionView;

@property (nonatomic, strong) UICollectionViewLayoutAttributes *movingItemAttributes;
@property (nonatomic, strong) NSIndexPath *toIndexPath;
@property (nonatomic) CGPoint panTranslation;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, strong) CADisplayLink *scrollTimer;
@property (nonatomic) _ScrollingDirection scrollingDirection;

@property (nonatomic, strong) UIView *dragUpToDeleteConfirmView;

@end

@implementation MTDraggableHelper

- (id)initWithCollectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if (self) {
        self.collectionView = collectionView;
        
        self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]
                                       initWithTarget:self
                                       action:@selector(handleLongPressGesture:)];
        self.longPressGestureRecognizer.delegate = self;
        [self.collectionView addGestureRecognizer:self.longPressGestureRecognizer];
        
        self.panGestureRecognizer = [[UIPanGestureRecognizer alloc]
                                      initWithTarget:self
                                     action:@selector(handlePanGesture:)];
        self.panGestureRecognizer.maximumNumberOfTouches = 1;
        self.panGestureRecognizer.delegate = self;
        [self.collectionView addGestureRecognizer:self.panGestureRecognizer];
}
    return self;
}

- (NSIndexPath *)indexPathForItemClosestToRect:(CGRect)frame
{
    NSArray *layoutAttrsInRect;
    NSInteger closestDist = NSIntegerMax;
    NSIndexPath *indexPath;
    NSIndexPath *toIndexPath = self.toIndexPath;
    
    // We need original positions of cells
    self.toIndexPath = nil;
    layoutAttrsInRect = [self.collectionView.collectionViewLayout
                         layoutAttributesForElementsInRect:self.collectionView.bounds];
    self.toIndexPath = toIndexPath;
    
    CGPoint point = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    
    // What cell are we closest to?
    for (UICollectionViewLayoutAttributes *layoutAttr in layoutAttrsInRect) {
        if (layoutAttr.representedElementCategory == UICollectionElementCategoryCell)  {
            CGFloat xd = layoutAttr.center.x - point.x;
            CGFloat yd = layoutAttr.center.y - point.y;
            NSInteger dist = sqrtf(xd*xd + yd*yd);
            if (dist < closestDist) {
                closestDist = dist;
                indexPath = layoutAttr.indexPath;
            }
        }
    }
    
    return indexPath;
}

- (CGRect)movingItemFrame
{
    return CGRectOffset(self.movingItemAttributes.frame, 0, self.panTranslation.y);
}

#pragma mark - Scrolling

- (void)invalidatesScrollTimer
{
    if (self.scrollTimer != nil) {
        [self.scrollTimer invalidate];
        self.scrollTimer = nil;
    }
    self.scrollingDirection = _ScrollingDirectionUnknown;
}

- (void)setupScrollTimerInDirection:(_ScrollingDirection)direction {
    self.scrollingDirection = direction;
    if (self.scrollTimer == nil) {
        self.scrollTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
        [self.scrollTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)handleScroll:(NSTimer *)timer
{
    CGSize frameSize = self.collectionView.bounds.size;
    CGSize contentSize = self.collectionView.contentSize;
    CGPoint contentOffset = self.collectionView.contentOffset;
    CGFloat distance = SCROLLING_SPEED / 60.f;
    CGPoint translation = CGPointZero;
    
    switch (self.scrollingDirection) {
        case _ScrollingDirectionUp: {
            distance = -distance;
            if ((contentOffset.y + distance) <= 0.f) {
                distance = -contentOffset.y;
            }
            translation = CGPointMake(0.f, distance);
        } break;
        case _ScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height;
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
            translation = CGPointMake(0.f, distance);
        } break;
        case _ScrollingDirectionLeft: {
            distance = -distance;
            if ((contentOffset.x + distance) <= 0.f) {
                distance = -contentOffset.x;
            }
            translation = CGPointMake(distance, 0.f);
        } break;
        case _ScrollingDirectionRight: {
            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width;
            if ((contentOffset.x + distance) >= maxX) {
                distance = maxX - contentOffset.x;
            }
            translation = CGPointMake(distance, 0.f);
        } break;
        default: break;
    }
    
    self.collectionView.contentOffset = _CGPointAdd(contentOffset, translation);
    self.panTranslation = _CGPointAdd([self.panGestureRecognizer translationInView:self.collectionView], translation);
    [self.panGestureRecognizer setTranslation:self.panTranslation inView:self.collectionView];
    
    // Warp items while scrolling
    NSIndexPath *indexPath = [self indexPathForItemClosestToRect:[self movingItemFrame]];
    [self warpToIndexPath:indexPath];
}

- (void)warpToIndexPath:(NSIndexPath *)indexPath
{
    BOOL validIndexPath = YES;
    
    id<UICollectionViewDataSource_Draggable> dataSource = (id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource;

    if ([dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:toIndexPath:)] == YES
        && [dataSource
            collectionView:self.collectionView
            canMoveItemAtIndexPath:self.movingItemAttributes.indexPath
            toIndexPath:indexPath] == NO) {
            validIndexPath = NO;
    }

    [self.collectionView performBatchUpdates:^{
        if (validIndexPath) {
            self.toIndexPath = indexPath;
        }
    } completion:nil];
}

#pragma mark - Item deletion

- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<UICollectionViewDataSource_Draggable> dataSource = (id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource;

    if ([dataSource respondsToSelector:@selector(collectionView:canDeleteItemAtIndexPath:)])
    {
        return [dataSource collectionView:self.collectionView canDeleteItemAtIndexPath:indexPath];
    }
    return NO;
}

- (void)showDeletionConfirmationViewForItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    if (!self.dragUpToDeleteConfirmView)
    {
        id<UICollectionViewDelegate_Draggable> delegate = (id<UICollectionViewDelegate_Draggable>)self.collectionView.delegate;
        if ([delegate respondsToSelector:@selector(collectionView:deletionConfirmationViewForItemAtIndexPath:)]) {
            self.dragUpToDeleteConfirmView = [delegate
                                              collectionView:self.collectionView deletionConfirmationViewForItemAtIndexPath:indexPath];
            if (self.dragUpToDeleteConfirmView) {
                self.dragUpToDeleteConfirmView.center = CGPointMake(CGRectGetMidX(self.collectionView.bounds), CGRectGetMidY(self.collectionView.bounds));
                self.dragUpToDeleteConfirmView.layer.transform = CATransform3DMakeTranslation(0, 0, 1);
                [self.collectionView addSubview:self.dragUpToDeleteConfirmView];
                if (animated) {
                    self.dragUpToDeleteConfirmView.layer.transform = CATransform3DScale(self.dragUpToDeleteConfirmView.layer.transform, 0.1, 0.1, 0.1);
                    [UIView animateWithDuration:0.3 animations:^{
                        self.dragUpToDeleteConfirmView.layer.transform = CATransform3DMakeTranslation(0, 0, 1);
                    }];
                }
            }
        }
    }
}

- (void)hideDeletionConfirmationViewAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.dragUpToDeleteConfirmView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.dragUpToDeleteConfirmView removeFromSuperview];
            self.dragUpToDeleteConfirmView = nil;
        }];
    } else {
        [self.dragUpToDeleteConfirmView removeFromSuperview];
        self.dragUpToDeleteConfirmView = nil;
    }
}

#pragma mark - Guesture recognizer delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.longPressGestureRecognizer) {
        return self.collectionView.viewMode == MTCardLayoutViewModeDefault;
    }

    if (gestureRecognizer == self.panGestureRecognizer)
    {
        if (self.collectionView.viewMode == MTCardLayoutViewModeDefault &&
            !self.movingItemAttributes.indexPath) {
            return NO;
        }
        
        CGPoint point = [gestureRecognizer locationInView:self.collectionView];
        id<UICollectionViewDelegate_Draggable> delegate = (id<UICollectionViewDelegate_Draggable>)self.collectionView.delegate;
        if ([delegate respondsToSelector:@selector(collectionView:shouldRecognizePanGestureAtPoint:)] &&
            ![delegate collectionView:self.collectionView shouldRecognizePanGestureAtPoint:point]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ((gestureRecognizer == self.panGestureRecognizer && otherGestureRecognizer == self.longPressGestureRecognizer) ||
        (gestureRecognizer == self.longPressGestureRecognizer && otherGestureRecognizer == self.panGestureRecognizer)) {
        return YES;
    }
    return NO;
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender
{
    if (self.collectionView.viewMode != MTCardLayoutViewModeDefault) {
        return;
    }
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        return;
    }
    
    id<UICollectionViewDataSource_Draggable> dataSource = (id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource;
    id<UICollectionViewDelegate_Draggable> delegate = (id<UICollectionViewDelegate_Draggable>)self.collectionView.delegate;

    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint touchLocation = [sender locationInView:self.collectionView];
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:touchLocation];

            if (indexPath == nil) {
                return;
            }
            if (![dataSource collectionView:self.collectionView canMoveItemAtIndexPath:indexPath]) {
                return;
            }
            
            // Start warping
            self.movingItemAttributes = [[self.collectionView layoutAttributesForItemAtIndexPath:indexPath] copy];
            self.toIndexPath = indexPath;
            self.panTranslation = CGPointZero;
            [self.collectionView performBatchUpdates:nil completion:nil];
            
        } break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if(self.movingItemAttributes == nil) {
                return;
            }
            
            // Need these for later, but need to nil out layoutHelper's references sooner
            NSIndexPath *fromIndexPath = self.movingItemAttributes.indexPath;
            NSIndexPath *toIndexPath = self.toIndexPath;
            
            // Move the item
            [self.collectionView performBatchUpdates:^{
                [dataSource collectionView:self.collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                [self.collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                self.movingItemAttributes = nil;
                self.toIndexPath = nil;
            } completion:^(BOOL finished) {
                if ([delegate respondsToSelector:@selector(collectionView:didMoveItemAtIndexPath:toIndexPath:)]) {
                    [delegate collectionView:self.collectionView didMoveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                }
            }];
            
            [self invalidatesScrollTimer];
        } break;

        default: break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (self.collectionView.viewMode == MTCardLayoutViewModePresenting) {
        
        UICollectionView *collectionView = self.collectionView;
        NSIndexPath *indexPath = [[collectionView indexPathsForSelectedItems] firstObject];
        if (!indexPath) return;
        
        BOOL canDelete = [self canDeleteItemAtIndexPath:indexPath];
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
        {
            [self showDeletionConfirmationViewForItemAtIndexPath:indexPath animated:YES];
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
                [self.collectionView deselectAndNotifyDelegate:indexPath];
                [collectionView performBatchUpdates:nil completion:nil];
                [self hideDeletionConfirmationViewAnimated:YES];
                return;
            }
            else if (canDelete && self.dragUpToDeleteConfirmView)
            {
                self.dragUpToDeleteConfirmView.alpha = MAX(0.0, MIN(1.0, -translatedY/DRAG_ACTION_LIMIT));
                if ([self.dragUpToDeleteConfirmView isKindOfClass:[UIImageView class]]) {
                    ((UIImageView *)self.dragUpToDeleteConfirmView).highlighted = translation.y < -DRAG_ACTION_LIMIT;
                }
            }
        }
        
        if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled)
        {
            id<UICollectionViewDataSource_Draggable> dataSource = (id<UICollectionViewDataSource_Draggable>)collectionView.dataSource;
            id<UICollectionViewDelegate_Draggable> delegate = (id<UICollectionViewDelegate_Draggable>)collectionView.delegate;
            if (canDelete && gestureRecognizer.state != UIGestureRecognizerStateCancelled && translation.y < -DRAG_ACTION_LIMIT)
            {
                // Delete the item
                [collectionView performBatchUpdates:^{
                    [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
                    [dataSource collectionView:collectionView deleteItemAtIndexPath:indexPath];
                    [collectionView deleteItemsAtIndexPaths:@[indexPath]];
                } completion:^(BOOL finished) {
                    if ([delegate respondsToSelector:@selector(collectionView:didDeleteItemAtIndexPath:)]) {
                        [delegate collectionView:self.collectionView didDeleteItemAtIndexPath:indexPath];
                    }
                }];
            }
            else
            {
                [UIView animateWithDuration:0.3 animations:^{
                    cell.frame = originFrame;
                } completion:nil];
            }
            
            [self hideDeletionConfirmationViewAnimated:YES];
        }
        
    } else { // self.collectionView.viewMode == MTCardLayoutViewModeDefault
        if (!self.movingItemAttributes) {
            return;
        }
        
        if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
            // Scroll when necessary
            self.panTranslation = [gestureRecognizer translationInView:self.collectionView];
            CGPoint touchLocation = [gestureRecognizer locationInView:self.collectionView];
            CGRect frame = [self movingItemFrame];
            
            if (frame.origin.y < CGRectGetMinY(self.collectionView.bounds) + SCROLLING_EDGE_INSET) {
                [self setupScrollTimerInDirection:_ScrollingDirectionUp];
            }
            else if (touchLocation.y > (CGRectGetMaxY(self.collectionView.bounds) - SCROLLING_EDGE_INSET)) {
                [self setupScrollTimerInDirection:_ScrollingDirectionDown];
            }
            else {
                [self invalidatesScrollTimer];
            }
            
            // Avoid warping a second time while scrolling
            if (self.scrollingDirection > _ScrollingDirectionUnknown) {
                return;
            }

            // Warp item to finger location
            NSIndexPath *indexPath = [self indexPathForItemClosestToRect:frame];
            [self warpToIndexPath:indexPath];
        }
    }
}

@end
