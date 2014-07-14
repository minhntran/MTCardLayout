#import "ViewController.h"
#import "PassCell.h"
#import "MTCardLayout.h"
#import "MTDraggableCardLayout.h"

@interface ViewController ()

@property (nonatomic, strong) SearchViewController *searchViewController;

@end

@implementation ViewController

#pragma mark Status Bar color

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];

    self.searchViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SearchViewController"];
    self.searchViewController.delegate = self;
	self.collectionView.backgroundView = self.searchViewController.view;
}

#pragma mark - UICollectionViewDatasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return 20;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	PassCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"pass" forIndexPath:indexPath];

	cell.titleLabel.text = [NSString stringWithFormat:@"Title %d", (int)indexPath.item];
	return cell;
}

- (UIImage *)collectionView:(UICollectionView *)collectionView cellImageForDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
	CGSize size = cell.bounds.size;
	size.height = 72.0;
	
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
	CGContextRef context = UIGraphicsGetCurrentContext();
	[cell.layer renderInContext:context];
	
	UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

- (CGAffineTransform)collectionView:(UICollectionView *)collectionView transformForDraggingItemAtIndexPath:(NSIndexPath *)indexPath duration:(NSTimeInterval *)duration
{
	return CGAffineTransformMakeScale(1.05f, 1.05f);
}

- (BOOL)collectionView:(LSCollectionViewHelper *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(LSCollectionViewHelper *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    
}

#pragma mark SearchCell

- (void)searchControllerWillBeginSearch:(SearchViewController *)controller
{
    if (!self.cardLayout.presenting)
    {
        [self.collectionView performBatchUpdates:^{
            self.cardLayout.presenting = YES;
        } completion:nil];
    }
}

- (void)searchControllerWillEndSearch:(SearchViewController *)controller
{
    if (!self.cardLayout.presenting)
    {
        [self.collectionView performBatchUpdates:^{
            self.cardLayout.presenting = NO;
        } completion:nil];
    }
}

@end
