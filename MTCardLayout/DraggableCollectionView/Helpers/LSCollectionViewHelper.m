//
//  Copyright (c) 2013 Luke Scott
//  https://github.com/lukescott/DraggableCollectionView
//  Distributed under MIT license
//

#import "LSCollectionViewHelper.h"
#import "UICollectionViewLayout_Warpable.h"
#import "UICollectionViewDataSource_Draggable.h"
#import "LSCollectionViewLayoutHelper.h"
#import <QuartzCore/QuartzCore.h>
#import "UICollectionView+Draggable.h"

static int kObservingCollectionViewLayoutContext;
static int kObservingCollectionViewOffset;

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

@interface LSCollectionViewHelper ()
{
    NSIndexPath *lastIndexPath;
    UIImageView *mockCell;
    CGPoint mockCenter;
    CGPoint fingerTranslation;
    CADisplayLink *timer;
    _ScrollingDirection scrollingDirection;
    BOOL canWarp;
    BOOL canScroll;
	BOOL _hasShouldAlterTranslationDelegateMethod;
    CGPoint _dropOnToDeleteViewCenter;
}
@property (readonly, nonatomic) LSCollectionViewLayoutHelper *layoutHelper;
@end

@implementation LSCollectionViewHelper

- (id)initWithCollectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if (self) {
        _collectionView = collectionView;
        [_collectionView addObserver:self
                          forKeyPath:@"collectionViewLayout"
                             options:0
                             context:&kObservingCollectionViewLayoutContext];
		[_collectionView addObserver:self
                          forKeyPath:@"contentOffset"
                             options:0
                             context:&kObservingCollectionViewOffset];

        _scrollingEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
        _scrollingSpeed = 300.f;
        
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]
                                       initWithTarget:self
                                       action:@selector(handleLongPressGesture:)];
        [_collectionView addGestureRecognizer:_longPressGestureRecognizer];
        
        _panPressGestureRecognizer = [[UIPanGestureRecognizer alloc]
                                      initWithTarget:self action:@selector(handlePanGesture:)];
        _panPressGestureRecognizer.delegate = self;

        [_collectionView addGestureRecognizer:_panPressGestureRecognizer];

//        This causes crashes, ios bug?
//        for (UIGestureRecognizer *gestureRecognizer in _collectionView.gestureRecognizers) {
//            if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
//                [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
//                break;
//            }
//        }
        
        [self layoutChanged];
    }
    return self;
}

- (void)unbindFromCollectionView:(UICollectionView *)collectionView
{
	[collectionView removeObserver:self forKeyPath:@"collectionViewLayout"];
	[collectionView removeObserver:self forKeyPath:@"contentOffset"];
}

- (LSCollectionViewLayoutHelper *)layoutHelper
{
    return [(id <UICollectionViewLayout_Warpable>)self.collectionView.collectionViewLayout layoutHelper];
}

- (void)layoutChanged
{
    canWarp = [self.collectionView.collectionViewLayout conformsToProtocol:@protocol(UICollectionViewLayout_Warpable)];
    canScroll = [self.collectionView.collectionViewLayout respondsToSelector:@selector(scrollDirection)];
    _longPressGestureRecognizer.enabled = _panPressGestureRecognizer.enabled = canWarp && self.enabled;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &kObservingCollectionViewOffset) {
		if ([self.dropOnToDeleteView superview]) {
            CGRect bounds = self.collectionView.bounds;
			self.dropOnToDeleteView.center = CGPointMake(CGRectGetMinX(bounds) + _dropOnToDeleteViewCenter.x, CGRectGetMinY(bounds) + _dropOnToDeleteViewCenter.y);
		}
	}
    else if (context == &kObservingCollectionViewLayoutContext) {
        [self layoutChanged];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setDropOnToDeleteView:(UIImageView *)dropOnToDeleteView
{
	_dropOnToDeleteView = dropOnToDeleteView;
	_dropOnToDeleteViewCenter = dropOnToDeleteView.center;
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    _longPressGestureRecognizer.enabled = canWarp && enabled;
    _panPressGestureRecognizer.enabled = canWarp && enabled;
}

- (NSIndexPath *)indexPathForMovingItem
{
	if (!mockCell) return nil;
    return self.layoutHelper.fromIndexPath;
}

- (UIImage *)imageFromCell:(UICollectionViewCell *)cell {

	UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0);
	[cell.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    return image;
}

- (void)invalidatesScrollTimer {
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    scrollingDirection = _ScrollingDirectionUnknown;
}

- (void)setupScrollTimerInDirection:(_ScrollingDirection)direction {
    scrollingDirection = direction;
    if (timer == nil) {
        timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
        [timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if([gestureRecognizer isEqual:_panPressGestureRecognizer]) {
        return self.layoutHelper.fromIndexPath != nil;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer isEqual:_longPressGestureRecognizer]) {
        return [otherGestureRecognizer isEqual:_panPressGestureRecognizer];
    }
    
    if ([gestureRecognizer isEqual:_panPressGestureRecognizer]) {
        return [otherGestureRecognizer isEqual:_longPressGestureRecognizer];
    }
    
    return NO;
}

- (NSIndexPath *)indexPathForItemClosestToPoint:(CGPoint)point
{
    NSArray *layoutAttrsInRect;
    NSInteger closestDist = NSIntegerMax;
    NSIndexPath *indexPath;
    NSIndexPath *toIndexPath = self.layoutHelper.toIndexPath;
    
    // We need original positions of cells
    self.layoutHelper.toIndexPath = nil;
    layoutAttrsInRect = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:self.collectionView.bounds];
    self.layoutHelper.toIndexPath = toIndexPath;
    
    // What cell are we closest to?
    for (UICollectionViewLayoutAttributes *layoutAttr in layoutAttrsInRect) {
        if (layoutAttr.representedElementCategory == UICollectionElementCategoryCell)  {
            if (CGRectContainsPoint(layoutAttr.frame, point)) {
                closestDist = 0;
                indexPath = layoutAttr.indexPath;
            } else {
                CGFloat xd = layoutAttr.center.x - point.x;
                CGFloat yd = layoutAttr.center.y - point.y;
                NSInteger dist = sqrtf(xd*xd + yd*yd);
                if (dist < closestDist) {
                    closestDist = dist;
                    indexPath = layoutAttr.indexPath;
                }
            }
        }
    }
    
    // Are we closer to being the last cell in a different section?
    NSInteger sections = [self.collectionView numberOfSections];
    for (NSInteger i = 0; i < sections; ++i) {
        if (i == self.layoutHelper.fromIndexPath.section) {
            continue;
        }
        NSInteger items = [self.collectionView numberOfItemsInSection:i];
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:items - 1 inSection:i];
        UICollectionViewLayoutAttributes *layoutAttr;
        CGFloat xd, yd;
        
        if (items > 0) {
            layoutAttr = [self.collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:nextIndexPath];
            xd = layoutAttr.center.x - point.x;
            yd = layoutAttr.center.y - point.y;
        } else {
            // Trying to use layoutAttributesForItemAtIndexPath while section is empty causes EXC_ARITHMETIC (division by zero items)
            // So we're going to ask for the header instead. It doesn't have to exist.
            layoutAttr = [self.collectionView.collectionViewLayout layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                                  atIndexPath:nextIndexPath];
            xd = layoutAttr.frame.origin.x - point.x;
            yd = layoutAttr.frame.origin.y - point.y;
        }
        
        NSInteger dist = sqrtf(xd*xd + yd*yd);
        if (dist < closestDist) {
            closestDist = dist;
            indexPath = layoutAttr.indexPath;
        }
    }
    
    return indexPath;
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateChanged) {
        return;
    }
    if (![self.collectionView.dataSource conformsToProtocol:@protocol(UICollectionViewDataSource_Draggable)]) {
        return;
    }
    
	_hasShouldAlterTranslationDelegateMethod = [self.collectionView.dataSource respondsToSelector:@selector(collectionView:alterTranslation:)];
	
	CGPoint point = [sender locationInView:self.collectionView];
    NSIndexPath *indexPath = [self indexPathForItemClosestToPoint:point];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            if (indexPath == nil) {
                return;
            }
            if (![(id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource
                  collectionView:self.collectionView
                  canMoveItemAtIndexPath:indexPath]) {
                return;
            }
            // Create mock cell to drag around
			UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            cell.highlighted = NO;
            [mockCell removeFromSuperview];
            mockCell = [[UIImageView alloc] initWithFrame:cell.frame];
			mockCell.alpha = 0.8;
			if ([self.collectionView.dataSource respondsToSelector:@selector(collectionView:imageForDraggingItemAtIndexPath:)]) {
				mockCell.image = [(id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource
								  collectionView:self.collectionView imageForDraggingItemAtIndexPath:indexPath];
			}
			if (mockCell.image == nil) {
				mockCell.image = [self imageFromCell:cell];
			}
			[mockCell sizeToFit];
            
			// Add shadow
            [mockCell.layer setMasksToBounds:NO ];
			[mockCell.layer setShadowColor:[[UIColor blackColor ] CGColor ] ];
			[mockCell.layer setShadowOpacity:0.65 ];
			[mockCell.layer setShadowRadius:10.0 ];
			[mockCell.layer setShadowOffset:CGSizeMake( 0 , 0 ) ];
            [mockCell.layer setShadowPath:[[UIBezierPath bezierPathWithRect:mockCell.bounds ] CGPath ] ];
            
            mockCenter = mockCell.center;
            [self.collectionView addSubview:mockCell];
			if (self.dropOnToDeleteView) {
				BOOL canDelete = NO;
                if ([self.collectionView.dataSource respondsToSelector:@selector(collectionView:canDeleteItemAtIndexPath:)]) {
                    canDelete = [(id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource
                                      collectionView:self.collectionView canDeleteItemAtIndexPath:indexPath];
                }
				if (canDelete)
				{
					CGRect bounds = self.collectionView.bounds;
					self.dropOnToDeleteView.center = CGPointMake(CGRectGetMinX(bounds) + _dropOnToDeleteViewCenter.x, CGRectGetMinY(bounds) + _dropOnToDeleteViewCenter.y);
					[self.dropOnToDeleteView setHighlighted:NO];
					[self.collectionView addSubview:self.dropOnToDeleteView];
					self.dropOnToDeleteView.alpha = 0.2;
				}
            }
			
			if ([self.collectionView.dataSource respondsToSelector:@selector(collectionView:transformForDraggingItemAtIndexPath:duration:)]) {
				NSTimeInterval duration = 0.3;
				CGAffineTransform transform = [(id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource collectionView:self.collectionView transformForDraggingItemAtIndexPath:indexPath duration:&duration];
				[UIView animateWithDuration:duration animations:^{
					mockCell.transform = transform;
				} completion:nil];
			}
            
            // Start warping
            lastIndexPath = indexPath;
            self.layoutHelper.fromIndexPath = indexPath;
            self.layoutHelper.hideIndexPath = indexPath;
            self.layoutHelper.toIndexPath = indexPath;
            [self.collectionView.collectionViewLayout invalidateLayout];
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if(self.layoutHelper.fromIndexPath == nil) {
                return;
            }
            // Need these for later, but need to nil out layoutHelper's references sooner
            NSIndexPath *fromIndexPath = self.layoutHelper.fromIndexPath;
            NSIndexPath *toIndexPath = self.layoutHelper.toIndexPath;
            id<UICollectionViewDataSource_Draggable> dataSource = (id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource;

			BOOL toDelete = sender.state == UIGestureRecognizerStateEnded && [self.dropOnToDeleteView isHighlighted];
			
            if (toDelete) {
                // Delete the item
                [self.collectionView performBatchUpdates:^{
                    [dataSource collectionView:self.collectionView deleteItemAtIndexPath:fromIndexPath];
                    [self.collectionView deleteItemsAtIndexPaths:@[fromIndexPath]];
                    self.layoutHelper.fromIndexPath = nil;
                    self.layoutHelper.toIndexPath = nil;
                } completion:^(BOOL finished) {
                    if ([dataSource respondsToSelector:@selector(collectionView:didDeleteItemAtIndexPath:)]) {
                        [dataSource collectionView:self.collectionView didDeleteItemAtIndexPath:fromIndexPath];
                    }
                }];

                [UIView
                 animateWithDuration:0.3
                 animations:^{
                     mockCell.center = self.dropOnToDeleteView.center;
                     mockCell.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(10), 0.01, 0.01);
                     self.dropOnToDeleteView.alpha = 0.0;
                 }
                 completion:^(BOOL finished) {
                     [mockCell removeFromSuperview];
                     mockCell = nil;
                     [self.dropOnToDeleteView removeFromSuperview];
                     self.dropOnToDeleteView.alpha = 1.0;
                     self.layoutHelper.hideIndexPath = nil;
                     [self.collectionView.collectionViewLayout invalidateLayout];
                 }];
            }
            else
            {
                // Move the item
                [self.collectionView performBatchUpdates:^{
                    [dataSource collectionView:self.collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                    [self.collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                    self.layoutHelper.fromIndexPath = nil;
                    self.layoutHelper.toIndexPath = nil;
                } completion:^(BOOL finished) {
                    if ([dataSource respondsToSelector:@selector(collectionView:didMoveItemAtIndexPath:toIndexPath:)]) {
                        [dataSource collectionView:self.collectionView didMoveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                    }
                }];

                UICollectionViewLayoutAttributes *layoutAttributes = [self.collectionView layoutAttributesForItemAtIndexPath:self.layoutHelper.hideIndexPath];
                [UIView
                 animateWithDuration:0.3
                 animations:^{
                     CGRect frame = layoutAttributes.frame;
                     frame.size = mockCell.frame.size;
                     mockCell.frame = frame;
                     mockCell.transform = CGAffineTransformIdentity;
                 }
                 completion:^(BOOL finished) {
                     [mockCell removeFromSuperview];
                     mockCell = nil;
                     [self.dropOnToDeleteView removeFromSuperview];
                     self.layoutHelper.hideIndexPath = nil;
                     [self.collectionView.collectionViewLayout invalidateLayout];
                 }];
            }
            
            // Reset
            [self invalidatesScrollTimer];
            lastIndexPath = nil;
        } break;
        default: break;
    }
}

- (void)warpToIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath == nil || [lastIndexPath isEqual:indexPath]) {
        return;
    }
    lastIndexPath = indexPath;
    
    if ([self.collectionView.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:toIndexPath:)] == YES
        && [(id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource
            collectionView:self.collectionView
            canMoveItemAtIndexPath:self.layoutHelper.fromIndexPath
            toIndexPath:indexPath] == NO) {
        return;
    }
    [self.collectionView performBatchUpdates:^{
        self.layoutHelper.hideIndexPath = indexPath;
        self.layoutHelper.toIndexPath = indexPath;
    } completion:nil];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender
{
    if(sender.state == UIGestureRecognizerStateChanged) {
        // Move mock to match finger
        fingerTranslation = [sender translationInView:self.collectionView];
		if (_hasShouldAlterTranslationDelegateMethod) {
			[(id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource collectionView:self.collectionView alterTranslation:&fingerTranslation];
		}

        UICollectionViewLayout<UICollectionViewLayout_Warpable> *layout = (UICollectionViewLayout<UICollectionViewLayout_Warpable> *)self.collectionView.collectionViewLayout;
        if ([layout respondsToSelector:@selector(dragDirection)]) {
            UICollectionViewScrollDirection direction = [layout dragDirection];
            if (direction == UICollectionViewScrollDirectionHorizontal) fingerTranslation.y = 0;
            else if (direction == UICollectionViewScrollDirectionVertical) fingerTranslation.x = 0;
        }
        
        mockCell.center = _CGPointAdd(mockCenter, fingerTranslation);
        
        // Scroll when necessary
        if (canScroll) {
            UICollectionViewLayout<UICollectionViewLayout_Warpable> *scrollLayout = (UICollectionViewLayout<UICollectionViewLayout_Warpable>*)self.collectionView.collectionViewLayout;
            if([scrollLayout scrollDirection] == UICollectionViewScrollDirectionVertical) {
                if (mockCell.center.y < (CGRectGetMinY(self.collectionView.bounds) + self.scrollingEdgeInsets.top)) {
                    [self setupScrollTimerInDirection:_ScrollingDirectionUp];
                }
                else {
                    if (mockCell.center.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingEdgeInsets.bottom)) {
                        [self setupScrollTimerInDirection:_ScrollingDirectionDown];
                    }
                    else {
                        [self invalidatesScrollTimer];
                    }
                }
            }
            else {
                if (mockCell.center.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingEdgeInsets.left)) {
                    [self setupScrollTimerInDirection:_ScrollingDirectionLeft];
                } else {
                    if (mockCell.center.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingEdgeInsets.right)) {
                        [self setupScrollTimerInDirection:_ScrollingDirectionRight];
                    } else {
                        [self invalidatesScrollTimer];
                    }
                }
            }
        }
        
        // Avoid warping a second time while scrolling
        if (scrollingDirection > _ScrollingDirectionUnknown) {
            return;
        }
        
        // Warp item to finger location
        CGPoint point = [sender locationInView:self.collectionView];
        NSIndexPath *indexPath = [self indexPathForItemClosestToPoint:point];
        [self warpToIndexPath:indexPath];
        
		// Delete view hit test
		if ([self dropOnToDeleteView] && [self.dropOnToDeleteView superview])
		{
			BOOL highlighted = CGRectContainsPoint(self.dropOnToDeleteView.frame, point);
			[self.dropOnToDeleteView setHighlighted:highlighted];
			if (!highlighted)
			{
				CGPoint center = self.dropOnToDeleteView.center;
				CGFloat distance = (center.x - point.x) * (center.x - point.x) + (center.y - point.y) * (center.y - point.y);
				self.dropOnToDeleteView.alpha = (2 - atan(distance / 10000.0)) / 2;
			}
			else
			{
				self.dropOnToDeleteView.alpha = 1.0;
			}
		}
    }
}

- (void)handleScroll:(NSTimer *)timer {
    if (scrollingDirection == _ScrollingDirectionUnknown) {
        return;
    }
    
    CGSize frameSize = self.collectionView.bounds.size;
    CGSize contentSize = self.collectionView.contentSize;
    CGPoint contentOffset = self.collectionView.contentOffset;
    CGFloat distance = self.scrollingSpeed / 60.f;
    CGPoint translation = CGPointZero;
    
    switch(scrollingDirection) {
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
    
    mockCenter  = _CGPointAdd(mockCenter, translation);
    mockCell.center = _CGPointAdd(mockCenter, fingerTranslation);
    self.collectionView.contentOffset = _CGPointAdd(contentOffset, translation);
    
    // Warp items while scrolling
    NSIndexPath *indexPath = [self indexPathForItemClosestToPoint:mockCell.center];
    [self warpToIndexPath:indexPath];
}

@end
