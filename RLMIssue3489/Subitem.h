@import Realm;

#import "Subsubitem.h"

@interface Subitem : RLMObject

@property NSString *uuid;
@property RLMArray<Subsubitem *><Subsubitem> *subsubitems;

@end
