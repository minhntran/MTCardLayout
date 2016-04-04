#import "ViewController.h"
#import "PassCell.h"
#import "MTCardLayout.h"
#import "UICollectionView+CardLayout.h"
#import "UICollectionView+DraggableCardLayout.h"
#import "MTCardLayoutHelper.h"
#import "SearchViewController.h"

@interface ViewController ()<SearchViewControllerDelegate, UICollectionViewDataSource_Draggable, UICollectionViewDelegate_Draggable>

@property (nonatomic, strong) SearchViewController *searchViewController;
@property (nonatomic, strong) NSMutableArray * items;

@end

@implementation ViewController

#pragma mark Status Bar color

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - View Lifecycle

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.collectionView setViewMode:MTCardLayoutViewModePresenting animated:YES completion:nil];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

    self.items = [NSMutableArray arrayWithCapacity:20];
    for (int i = 0; i < 20; i++)
    {
        [self.items addObject:[NSString stringWithFormat:@"Item %d", i]];
    }

    self.searchViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SearchViewController"];
    self.searchViewController.delegate = self;
	self.collectionView.backgroundView = self.searchViewController.view;
}

#pragma mark - UICollectionViewDatasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	PassCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"pass" forIndexPath:indexPath];

	cell.titleLabel.text = self.items[indexPath.item];
	return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSString * item = self.items[fromIndexPath.item];
    [self.items removeObjectAtIndex:fromIndexPath.item];
    [self.items insertObject:item atIndex:toIndexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}

- (BOOL)collectionView:(UICollectionView *)collectionView canDeleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView deleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.items removeObjectAtIndex:indexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView didDeleteItemAtIndexPath:(NSIndexPath *)indexPath
{
}

- (UIView *)collectionView:(UICollectionView *)collectionView deletionConfirmationViewForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"trashcan"] highlightedImage:[UIImage imageNamed:@"trashcan_red"]];
}

- (void)collectionView:(UICollectionView *)collectionView modifyMovingItemAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    layoutAttributes.transform3D = CATransform3DTranslate(layoutAttributes.transform3D, 0.0, -15.0, 0.0);
}

#pragma mark SearchCell

- (void)searchControllerWillBeginSearch:(SearchViewController *)controller
{
    if (self.collectionView.viewMode != MTCardLayoutViewModePresenting)
    {
        [self.collectionView setViewMode:MTCardLayoutViewModePresenting animated:YES completion:nil];
    }
}

- (void)searchControllerWillEndSearch:(SearchViewController *)controller
{
    if (self.collectionView.viewMode != MTCardLayoutViewModeDefault)
    {
        [self.collectionView setViewMode:MTCardLayoutViewModeDefault animated:YES completion:nil];
    }
}

#pragma mark Backside

- (IBAction)flip:(id)sender
{
	PassCell *cell = (PassCell *)[self.collectionView cellForItemAtIndexPath:[[self.collectionView indexPathsForSelectedItems] firstObject]];
	if (sender == cell.infoButton)
	{
		[cell flipTransitionWithOptions:UIViewAnimationOptionTransitionFlipFromLeft halfway:^(BOOL finished) {
			cell.infoButton.hidden = YES;
			cell.doneButton.hidden = NO;
		} completion:nil];
	}
	else
	{
		[cell flipTransitionWithOptions:UIViewAnimationOptionTransitionFlipFromRight halfway:^(BOOL finished) {
			cell.infoButton.hidden = NO;
			cell.doneButton.hidden = YES;
		} completion:nil];
	}
}

@end
