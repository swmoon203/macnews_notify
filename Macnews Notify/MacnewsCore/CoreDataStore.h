//
//  CoreDataStore.h
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 19..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//
/*
 Basic rules are:
 1. Use one [NSPersistentStoreCoordinator] per program. You don't need them per thread.
 2. Create one [NSManagedObjectContext] per thread.
 3. Never pass an [NSManagedObject] on a thread to the other thread.
 4. Instead, get the object IDs via -objectID and pass it to the other thread.
 
 More rules:
 1. Make sure you save the object into the store before getting the object ID. Until saved, they're temporary, and you can't access them from another thread.
 2. And beware of the merge policies if you make changes to the managed objects from more than one thread.
 3. NSManagedObjectContext's -mergeChangesFromContextDidSaveNotification: is helpful.
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataStore : NSObject

//Need implementation
- (NSURL *)managedObjectModelURL;
- (NSURL *)storeURL;
- (NSDictionary *)persistentStoreCoordinatorOptions;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSManagedObjectContext *)newManagedObjectContext;
- (NSManagedObjectContext *)newManagedObjectContext:(BOOL)autoMerge;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext; //main thread only

- (void)deleteAllEntities:(NSString *)entityName from:(NSManagedObjectContext *)context;
@end
