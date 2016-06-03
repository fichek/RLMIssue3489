@import Realm;

@class Subitem;

@interface Item : RLMObject

@property NSString *uuid;
@property NSString *name;
@property Subitem *subitem;

@end
