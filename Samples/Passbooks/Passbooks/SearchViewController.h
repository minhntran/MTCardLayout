#import <UIKit/UIKit.h>

@class SearchViewController;

@protocol SearchViewControllerDelegate <NSObject>
- (void)searchControllerWillBeginSearch:(SearchViewController *)controller;
- (void)searchControllerWillEndSearch:(SearchViewController *)controller;
@end

@interface SearchViewController : UIViewController
@property (nonatomic, weak) id<SearchViewControllerDelegate> delegate;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@end
