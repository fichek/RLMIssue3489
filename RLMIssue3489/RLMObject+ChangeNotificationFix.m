#import "RLMObject+ChangeNotificationFix.h"
#import <Realm/RLMSchema_Private.h>

@implementation RLMObject (ChangeNotificationFix)

+ (instancetype)cnf_createOrUpdateInRealm:(RLMRealm *)realm withValue:(NSDictionary *)value
{
    RLMObject *object;
    NSString *primaryKey = [self primaryKey];
    
    // only proceed if value is dictionary and this RLMObject subclass has primary key
    if (!primaryKey || ![value isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    // use Realm to get current object or create a new one, but only using primaryKey
    // because if it's provided with entire dictionary, it generates those unwanted
    // change notifications that are being prevented by this category
    object = [self createOrUpdateInRealm:realm
                               withValue:@{primaryKey: value[primaryKey]}];
    
    // get that object's schema and enumerate through its properties
    RLMObjectSchema *schema = [self sharedSchema];
    [schema.properties enumerateObjectsUsingBlock:^(RLMProperty * _Nonnull property, NSUInteger idx, BOOL * _Nonnull stop) {
        
        // skip the primary key property as that was populated by Realm's createOrUpdate...
        // since it can't be changed and will be skipped later on isEqual: check anyway
        if ([property.name isEqualToString:primaryKey]) {
            return; // only returns out of enumeration block
        }
        
        // if a property type is a child Realm object
        if (property.type == RLMPropertyTypeObject) {
            // get its class
            Class childClass = NSClassFromString(property.objectClassName);
            
            // and recursively create or update that object
            RLMObject *childObject = [childClass cnf_createOrUpdateInRealm:realm withValue:value[property.name]];
            
            // if our object's property already links to the same child object, do nothing to avoid change notification
            if ((object[property.name] || childObject) && ![object[property.name] isEqualToObject:childObject]) {
                object[property.name] = childObject;
            }
        }
        // for array properties we need to recursively create child objects and add them to array, similar to child objects
        else if (property.type == RLMPropertyTypeArray) {
            Class childClass = NSClassFromString(property.objectClassName);
            
            RLMArray *realmArray = object[property.name];
            NSArray *valueArray = value[property.name];
            [valueArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                RLMObject *childObject;
                childObject = [childClass cnf_createOrUpdateInRealm:realm withValue:obj];
                
                // if our object's array property already contains this child object, do nothing to avoid change notification
                if ([realmArray indexOfObject:childObject] == NSNotFound) {
                    [realmArray addObject:childObject];
                }
            }];
        }
        // skip properties of type linking objects because those are populated from the opposite side
        else if (property.type != RLMPropertyTypeLinkingObjects) {
            // get property's value from dictionary if it exists, or from current object or from default values
            id propertyValue = value[property.name] ?: object[property.name] ?: [self defaultPropertyValues][property.name];
            
            // if this property is optional, but we found no value in any of those three places, throw an exception
            if (!property.optional && !propertyValue) {
                @throw [NSException exceptionWithName:@"CNF_RLMObjectMissingValueException"
                                               reason:[NSString stringWithFormat:@"Missing value for required property %@", property.name]
                                             userInfo:nil];
            }
            
            // only update the value if the property doesn't already contain that same value
            if ((object[property.name] || propertyValue) && ![object[property.name] isEqual:propertyValue]) {
                object[property.name] = propertyValue;
            }
        }
    }];
    
    return object;
}

@end
