@import Realm;

@interface RLMObject (ChangeNotificationFix)

/// Recursively create or update Realm objects from an NSDictionary without generating change notifications when there are no value changes on updated objects.
+ (instancetype)cnf_createOrUpdateInRealm:(RLMRealm *)realm withValue:(NSDictionary *)value;

@end
