#import "ViewController.h"
#import "RLMObject+ChangeNotificationFix.h"
#import "Item.h"

@import Realm;

@interface ViewController ()

@property (strong, nonatomic) RLMResults *items;
@property (strong, nonatomic) RLMNotificationToken *notificationToken;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.items = [Item allObjects];
    
    self.notificationToken = [self.items addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
        if (change) {
            NSLog(@"%@ deletions, %@ insertions, %@ modifications, %@ total objects",
                  @(change.deletions.count),
                  @(change.insertions.count),
                  @(change.modifications.count),
                  @(results.count));
        }
        else {
            NSLog(@"%@ items at first load", @(results.count));
        }
    }];
}

- (IBAction)import:(UIButton *)sender
{
    // ("Import with the fix" button has tag = 1)
    [self importWithFix:sender.tag];
}

- (void)importWithFix:(BOOL)fix
{
    NSData *data = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Items"
                                                                         withExtension:@"json"]];
    
    NSArray *jsonItems = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:nil];
    
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        [jsonItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (fix) {
                [Item cnf_createOrUpdateInRealm:[RLMRealm defaultRealm]
                                      withValue:obj];
            }
            else {
                [Item createOrUpdateInDefaultRealmWithValue:obj];
            }
        }];
    }];
}

- (IBAction)clear:(UIButton *)sender
{
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        [[RLMRealm defaultRealm] deleteObjects:self.items];
    }];
}

@end
