#import "MTDraggableCardLayoutHelper.h"
#import "MTCommonTypes.h"
#import "UICollectionView+CardLayout.h"
#import "UICollectionView+DraggableCardLayout.h"
#import "MTDraggableCardLayout.h"

#define DEFAULT_ANIMATION_DURATION 0.25

#define SCROLLING_SPEED 300.f
#define SCROLLING_EDGE_INSET 50.f

#define DRAG_ACTION_LIMIT 150.0

typedef NS_ENUM(NSInteger, MTScrollingDirection) {
    MTScrollingDirectionUnknown = 0,
    MTScrollingDirectionUp,
    MTScrollingDirectionDown,
};

typedef NS_ENUM(NSInteger, MTDraggingAction) {
    MTDraggingActionNone,
    MTDraggingActionReorder,
    MTDraggingActionSwipeToDelete,
    MTDraggingActionDismissPresenting,
};

@interface MTDraggableCardLayoutHelper() <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UICollectionView *collectionView;

@property (nonatomic) MTDraggingAction draggingAction;
@property (nonatomic, copy) UICollectionViewLayoutAttributes *movingItemAttributes;
@property (nonatomic, strong) NSIndexPath *toIndexPath;
@property (nonatomic) CGPoint movingItemTranslation;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, strong) CADisplayLink *scrollTimer;
@property (nonatomic) MTScrollingDirection scrollingDirection;

@property (nonatomic, strong) UIView *deletionIndicatorView;

@end

@implementation MTDraggableCardLayoutHelper

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
    return CGRectOffset(self.movingItemAttributes.frame, self.movingItemTranslation.x, self.movingItemTranslation.y);
}

- (CGFloat)movingItemAlpha
{
    CGRect frame = self.movingItemAttributes.frame;
    CGPoint translation = self.movingItemTranslation;
    if (frame.size.width == 0 || frame.size.height == 0) return 1.0;
    
    CGFloat alphaH = translation.x > -DRAG_ACTION_LIMIT ? 1.0 : MAX(0.0, (frame.size.width + translation.x + DRAG_ACTION_LIMIT) / frame.size.width - 0.1);
    CGFloat alphaV = translation.y > -DRAG_ACTION_LIMIT ? 1.0 : MAX(0.0, (frame.size.height + translation.y + DRAG_ACTION_LIMIT) / frame.size.height - 0.1);

    return MIN(alphaH, alphaV);
}

- (void)updateMovingCell
{
    NSIndexPath *indexPath = self.movingItemAttributes.indexPath;
    NSAssert(indexPath, @"movingItemAttributes cannot be nil");
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if (!cell) return; // Cell is not visible
    
    cell.frame = self.movingItemFrame;
    cell.alpha = self.movingItemAlpha;
}

- (void)clearDraggingAction
{
    self.movingItemAttributes = nil;
    self.toIndexPath = nil;
    self.movingItemTranslation = CGPointZero;
    self.draggingAction = MTDraggingActionNone;
}

#pragma mark - Moving/Scrolling

- (BOOL)canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<UICollectionViewDataSource_Draggable> dataSource = (id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource;
    
    return [dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] &&
    [dataSource collectionView:self.collectionView canMoveItemAtIndexPath:indexPath];
}

- (void)invalidatesScrollTimer
{
    if (self.scrollTimer != nil) {
        [self.scrollTimer invalidate];
        self.scrollTimer = nil;
    }
    self.scrollingDirection = MTScrollingDirectionUnknown;
}

- (void)setupScrollTimerInDirection:(MTScrollingDirection)direction
{
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
    
    switch (self.scrollingDirection) {
        case MTScrollingDirectionUp: {
            distance = -distance;
            if ((contentOffset.y + distance) <= 0.f) {
                distance = -contentOffset.y;
            }
        } break;
        case MTScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height;
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
        } break;
        default: break;
    }
    
    contentOffset.y += distance;
    self.collectionView.contentOffset = contentOffset;
    self.movingItemTranslation = CGPointMake(0, [self.panGestureRecognizer translationInView:self.collectionView].y + distance);
    // Reset in the gesture as well
    [self.panGestureRecognizer setTranslation:self.movingItemTranslation inView:self.collectionView];
    
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

#pragma mark - Deleting

- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<UICollectionViewDataSource_Draggable> dataSource = (id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource;

    return [dataSource respondsToSelector:@selector(collectionView:canDeleteItemAtIndexPath:)] &&
        [dataSource collectionView:self.collectionView canDeleteItemAtIndexPath:indexPath];
}

- (void)showDeletionIndicatorAnimated:(BOOL)animated
{
    UICollectionView *collectionView = self.collectionView;
    NSIndexPath *indexPath = self.movingItemAttributes.indexPath;
    NSAssert(indexPath, @"movingItemAttributes cannot be nil");

    if (self.deletionIndicatorView) {
        [self.deletionIndicatorView removeFromSuperview];
        self.deletionIndicatorView = nil;
    }
    
    id<UICollectionViewDelegate_Draggable> delegate = (id<UICollectionViewDelegate_Draggable>)collectionView.delegate;
    if ([delegate respondsToSelector:@selector(collectionView:deletionIndicatorViewForItemAtIndexPath:)]) {
        self.deletionIndicatorView = [delegate collectionView:collectionView deletionIndicatorViewForItemAtIndexPath:indexPath];
        if (self.deletionIndicatorView) {
            CGPoint center;
            if (collectionView.viewMode == MTCardLayoutViewModePresenting) {
                center = CGPointMake(CGRectGetMidX(collectionView.bounds), CGRectGetMidY(collectionView.bounds));
            } else {
                CGRect frame = self.movingItemAttributes.frame;
                MTDraggableCardLayout *cardLayout = (MTDraggableCardLayout *)collectionView.collectionViewLayout;
                NSAssert([cardLayout isKindOfClass:[MTDraggableCardLayout class]], @"Collection layout is not of correct class");
                frame.size.height = cardLayout.metrics.minimumVisibleHeight;
                CGFloat padding = (frame.size.height - self.deletionIndicatorView.frame.size.height) / 2;
                center = CGPointMake(padding + self.deletionIndicatorView.frame.size.width / 2, CGRectGetMidY(frame));
            }
            
            self.deletionIndicatorView.center = center;
            self.deletionIndicatorView.layer.transform = CATransform3DMakeTranslation(0, 0, 1);
            [collectionView addSubview:self.deletionIndicatorView];
            if (animated) {
                self.deletionIndicatorView.layer.transform = CATransform3DScale(self.deletionIndicatorView.layer.transform, 0.1, 0.1, 0.1);
                [UIView animateWithDuration:DEFAULT_ANIMATION_DURATION animations:^{
                    self.deletionIndicatorView.layer.transform = CATransform3DMakeTranslation(0, 0, 1);
                }];
            }
        }
    }
}

- (void)updateDeletionIndicator
{
    if (self.deletionIndicatorView) {
        CGFloat offset = MIN(self.movingItemTranslation.x, self.movingItemTranslation.y); // expecting negative value
        self.deletionIndicatorView.alpha = MAX(0.0, MIN(1.0, -offset/DRAG_ACTION_LIMIT));
        if ([self.deletionIndicatorView isKindOfClass:[UIImageView class]]) {
            ((UIImageView *)self.deletionIndicatorView).highlighted = offset < -DRAG_ACTION_LIMIT;
        }
    }
}

- (void)hideDeletionIndicatorViewAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:DEFAULT_ANIMATION_DURATION animations:^{
            self.deletionIndicatorView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.deletionIndicatorView removeFromSuperview];
            self.deletionIndicatorView.alpha = 1.0;
            self.deletionIndicatorView = nil;
        }];
    } else {
        [self.deletionIndicatorView removeFromSuperview];
        self.deletionIndicatorView = nil;
    }
}


- (void)confirmDeletingItemAtIndexPath:(NSIndexPath *)indexPath completion:(void(^)(BOOL cancel))completion
{
    id<UICollectionViewDelegate_Draggable> delegate = (id<UICollectionViewDelegate_Draggable>)self.collectionView.delegate;
    if ([delegate respondsToSelector:@selector(collectionView:willDeleteItemAtIndexPath:completion:)]) {
        [delegate collectionView:self.collectionView willDeleteItemAtIndexPath:indexPath completion:completion];
    } else {
        completion(NO);
    }
}

- (void)finalizeDeletingItemWithSwipeDirection:(UISwipeGestureRecognizerDirection)direction
{
    UICollectionView *collectionView = self.collectionView;
    NSIndexPath *indexPath = self.movingItemAttributes.indexPath;
    NSAssert(indexPath, @"movingItemAttributes cannot be nil");

    CGRect originalFrame = self.movingItemAttributes.frame;
    
    [UIView animateWithDuration:DEFAULT_ANIMATION_DURATION animations:^{
        // Continue to move item off screen
        CGPoint translation = CGPointZero;
        switch (direction) {
            case UISwipeGestureRecognizerDirectionLeft:
                translation.x = -originalFrame.size.width + 1;
                break;
            case UISwipeGestureRecognizerDirectionUp:
                translation.y = -originalFrame.size.height + 1;
                break;
            case UISwipeGestureRecognizerDirectionRight:
                translation.x = originalFrame.size.width - 1;
                break;
            case UISwipeGestureRecognizerDirectionDown:
                translation.y = originalFrame.size.height - 1;
                break;
        }
        self.movingItemTranslation = translation;
        [self updateMovingCell];
        
        collectionView.userInteractionEnabled = NO;
        [self confirmDeletingItemAtIndexPath:indexPath completion:^(BOOL cancel) {
            collectionView.userInteractionEnabled = YES;
            
            if (cancel) {
                self.movingItemTranslation = CGPointZero;
                [UIView animateWithDuration:DEFAULT_ANIMATION_DURATION animations:^{
                    [self updateMovingCell];
                }];
            } else {
                id<UICollectionViewDataSource_Draggable> dataSource = (id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource;
                id<UICollectionViewDelegate_Draggable> delegate = (id<UICollectionViewDelegate_Draggable>)self.collectionView.delegate;

                [collectionView performBatchUpdates:^{
                    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
                    [dataSource collectionView:collectionView deleteItemAtIndexPath:indexPath];
                    [collectionView deleteItemsAtIndexPaths:@[indexPath]];
                } completion:^(BOOL finished) {
                    if ([delegate respondsToSelector:@selector(collectionView:didDeleteItemAtIndexPath:)]) {
                        [delegate collectionView:self.collectionView didDeleteItemAtIndexPath:indexPath];
                    }
                }];
            }

            [self clearDraggingAction];
        }];
    } completion:nil];
}

#pragma mark - Gesture Recognizers

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];

    if (!indexPath) return NO;
    
    if (gestureRecognizer == self.longPressGestureRecognizer) {
        return self.collectionView.viewMode == MTCardLayoutViewModeDefault;
    }

    if (gestureRecognizer == self.panGestureRecognizer) {
        id<UICollectionViewDelegate_Draggable> delegate = (id<UICollectionViewDelegate_Draggable>)self.collectionView.delegate;
        if ([delegate respondsToSelector:@selector(collectionView:shouldRecognizePanGestureAtPoint:)] &&
            ![delegate collectionView:self.collectionView shouldRecognizePanGestureAtPoint:point]) {
            return NO;
        }

        if (self.collectionView.viewMode == MTCardLayoutViewModeDefault && !self.movingItemAttributes) {
            CGPoint velocity = [self.panGestureRecognizer velocityInView:self.collectionView];
            if (fabs(velocity.x) < fabs(velocity.y)) {
                return NO;
            }
        }
        
        return YES;
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

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    UICollectionView *collectionView = self.collectionView;
    id<UICollectionViewDataSource_Draggable> dataSource = (id<UICollectionViewDataSource_Draggable>)collectionView.dataSource;
    id<UICollectionViewDelegate_Draggable> delegate = (id<UICollectionViewDelegate_Draggable>)collectionView.delegate;

    if (collectionView.viewMode != MTCardLayoutViewModeDefault) {
        return;
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        return;
    }

    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            if (self.draggingAction != MTDraggingActionNone) {
                return;
            }
            NSIndexPath *indexPath = [collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:collectionView]];
            if (indexPath == nil) {
                return;
            }
            
            if (![self canMoveItemAtIndexPath:indexPath]) {
                return;
            }
            
            // Start reordering item
            self.draggingAction = MTDraggingActionReorder;
            self.movingItemAttributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
            self.toIndexPath = indexPath;
            self.movingItemTranslation = CGPointZero;
            [collectionView performBatchUpdates:nil completion:nil];
        } break;

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (self.draggingAction != MTDraggingActionReorder) {
                return;
            }
            
            // Need these for later, but need to nil out layoutHelper's references sooner
            NSIndexPath *fromIndexPath = self.movingItemAttributes.indexPath;
            NSAssert(fromIndexPath, @"movingItemAttributes cannot be nil");
            NSIndexPath *toIndexPath = self.toIndexPath;
            NSAssert(toIndexPath, @"toIndexPath cannot be nil");
            
            // Move the item
            [collectionView performBatchUpdates:^{
                [dataSource collectionView:collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                [collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                [self clearDraggingAction];
            } completion:^(BOOL finished) {
                if ([delegate respondsToSelector:@selector(collectionView:didMoveItemAtIndexPath:toIndexPath:)]) {
                    [delegate collectionView:collectionView didMoveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                }
            }];

            [self invalidatesScrollTimer];
        } break;

        default: break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    UICollectionView *collectionView = self.collectionView;

    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (self.draggingAction == MTDraggingActionNone) {
            NSIndexPath *indexPath = [collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:collectionView]];
            if (indexPath == nil) {
                return;
            }
            if (collectionView.viewMode == MTCardLayoutViewModePresenting) {
                if (![indexPath isEqual:[[collectionView indexPathsForSelectedItems] firstObject]]) {
                    return;
                }
                self.draggingAction = MTDraggingActionDismissPresenting;
                self.movingItemAttributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
                [self showDeletionIndicatorAnimated:YES];
            } else if ([self canDeleteItemAtIndexPath:indexPath]) {
                self.draggingAction = MTDraggingActionSwipeToDelete;
                self.movingItemAttributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
                [self showDeletionIndicatorAnimated:YES];
            }
        }
    }
    
    if (self.draggingAction == MTDraggingActionNone) {
        return;
    }
    
    NSIndexPath *indexPath = self.movingItemAttributes.indexPath;
    NSAssert(indexPath, @"movingItemAttributes cannot be nil");

    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
       switch (self.draggingAction) {
            case MTDraggingActionDismissPresenting: {
                self.movingItemTranslation = CGPointMake(0, [gestureRecognizer translationInView:collectionView].y);
                [self updateMovingCell];
                [self updateDeletionIndicator];
                
                if (self.movingItemTranslation.y >= DRAG_ACTION_LIMIT)
                {
                    [collectionView deselectAndNotifyDelegate:indexPath];
                    [self clearDraggingAction];
                    [collectionView performBatchUpdates:nil completion:nil];
                }
            } break;
                
            case MTDraggingActionSwipeToDelete: {
                self.movingItemTranslation = CGPointMake(MIN(0, [gestureRecognizer translationInView:collectionView].x), 0);
                [self updateMovingCell];
                [self updateDeletionIndicator];
            } break;
                
            case MTDraggingActionReorder: {
                self.movingItemTranslation = CGPointMake(0, [gestureRecognizer translationInView:self.collectionView].y);
                CGPoint touchLocation = [gestureRecognizer locationInView:self.collectionView];
                CGRect frame = [self movingItemFrame];
                    
                if (frame.origin.y < CGRectGetMinY(self.collectionView.bounds) + SCROLLING_EDGE_INSET) {
                    [self setupScrollTimerInDirection:MTScrollingDirectionUp];
                }
                else if (touchLocation.y > (CGRectGetMaxY(self.collectionView.bounds) - SCROLLING_EDGE_INSET)) {
                    [self setupScrollTimerInDirection:MTScrollingDirectionDown];
                }
                else {
                    [self invalidatesScrollTimer];
                }
                    
                // Avoid warping a second time while scrolling
                if (self.scrollingDirection > MTScrollingDirectionUnknown) {
                    return;
                }
                    
                // Warp item to finger location
                NSIndexPath *indexPath = [self indexPathForItemClosestToRect:frame];
                [self warpToIndexPath:indexPath];
                
            } break;

            default:
                break;
        }
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded | gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
        if (self.draggingAction == MTDraggingActionSwipeToDelete || self.draggingAction == MTDraggingActionDismissPresenting)
        {
            NSIndexPath *indexPath = self.movingItemAttributes.indexPath;
            NSAssert(indexPath, @"movingItemAttributes cannot be nil");
            CGPoint translation = self.movingItemTranslation;

            if (gestureRecognizer.state != UIGestureRecognizerStateCancelled &&
                (translation.y < -DRAG_ACTION_LIMIT || translation.x < -DRAG_ACTION_LIMIT) &&
                [self canDeleteItemAtIndexPath:indexPath]) {
                UISwipeGestureRecognizerDirection direction = (self.draggingAction == MTDraggingActionSwipeToDelete) ?
                    UISwipeGestureRecognizerDirectionLeft : UISwipeGestureRecognizerDirectionUp;
                [self finalizeDeletingItemWithSwipeDirection:direction];
            } else {
                // Return item to original position
                self.movingItemTranslation = CGPointZero;
                [UIView animateWithDuration:DEFAULT_ANIMATION_DURATION animations:^{
                    [self updateMovingCell];
                } completion:nil];
                [self clearDraggingAction];
            }
            [self hideDeletionIndicatorViewAnimated:YES];
        }
    }
}

@end
