//  DataHandler.swift

import UIKit
import CoreData

class DataHandler: NSObject {

    let container: NSPersistentContainer
    let context: NSManagedObjectContext
    let entities: Dictionary<String, NSEntityDescription>.Keys
    /****************************
     *  INIT()
     *
     *  No @par init, refer to main AppDelegate
     *
     *  Required a core data implementation:
     *  (MARK: - Core Data Saving support and MARK: - Core Data stack)
     *  You shuold have that "sections" in AppDelegate.swift
     *  and a .xcdatamodel file. It are autogenerate in a single view
     *  project if core data checkbox is ticked. In an existing project
     *  you have to add it manually
     *
    *****************************/

    override init()
    {
        self.container = ((UIApplication.shared.delegate) as! AppDelegate).persistentContainer
        self.context = self.container.viewContext
        self.entities = self.container.managedObjectModel.entitiesByName.keys
    }
    /****************************
     *  INIT()
     *
     *  @DB: String, name of the container
     *
     *  Init for a global instance of DataHandler
     *  NO tested yet
     *
    *****************************/
    /*
    init(DB: String)
    {
        let container = NSPersistentContainer(name: DB)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        self.container = container
        self.context = self.container.viewContext
        self.entities = self.container.managedObjectModel.entitiesByName.keys
    */
    
    /****************************
     *  GET FROM CORE DATA
     *
     *  @par entity: String, entity (table) name
     *  @par predicate: NSPredicate, filter/s for the query, default = TRUEPREDICATE
     *  @par orderBy: [String:Bool], an array of pairs "Attribute", "IsAscending"
     *  @par limit: Int, limit of returned elements, default = 0
     *
     *  ret: [NSManagedObject]
     *
     *  Use this function to fetch (to get) an entity/ies in coreData.
     *  In case of error or no element found returns an empty array.
     *
    *****************************/
    func getFromCoreData(entity: String, predicate: NSPredicate = NSPredicate(value: true), orderBy: [String:Bool] = [:], limit: Int = 0) -> [NSManagedObject]
    {
        //check if @entity is a valid entity
        if(!self.entities.contains(entity))
        {
            return []
        }

        var dataArray = [NSManagedObject]()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)

        //SETS PREDICATE
        request.predicate = predicate

        //SETS SORTING
        if(orderBy.count > 0)
        {
            //array for request sort descriptors
            var sortArray = [NSSortDescriptor]()
            for by in orderBy
            {
                //key = attribute, value = boolean
                let sort = NSSortDescriptor(key: by.key, ascending: by.value)
                sortArray.append(sort)
            }
            //assigns sort descriptors
            request.sortDescriptors = sortArray
        }

        //SETS LIMIT
        if(limit != 0)
        {
            request.fetchLimit = limit
        }

        //SETS FAULTS
        request.returnsObjectsAsFaults = false
        
        //FETCHING
        do 
        {
            let result = try self.context.fetch(request)
            for data in result as! [NSManagedObject] 
            {
                dataArray.append(data)
            }
            return dataArray
        } catch {
            //manage error
            print("Failed")
        }
        return dataArray
    }

    /****************************
     *  CORE DATA INSERT
     *
     *  @par entity: String, entity (table) name
     *  @par fields: [String:Any], an array of pairs of Attribute,Value
     *
     *  ret: NSManagedObject, the created entity
     *
     *  This function does NOT save the context, it just create an new
     *  instance of @entity seeds with @fields in the context, but it
     *  does NOT store (save) it.
     *
    ****************************/

    private func coreDataInsert(entity: String, fields: [String:Any]) -> NSManagedObject
    {
        if(!self.entities.contains(entity))
        {
            return NSManagedObject()
        }
        
        let entity = NSEntityDescription.entity(forEntityName: entity, in: context)
        let newInstance = NSManagedObject(entity: entity!, insertInto: context)
        
        for field in fields
        {
            var setKey = ""
            var f = true
            for chr in field.key
            {
                setKey += String(chr)
                if(f)
                {
                    setKey = setKey.lowercased()
                }
                f = false
            }

            if(type(of:field.value) != NSNull.self && newInstance.entity.attributesByName.keys.contains(setKey))
            {
                newInstance.setValue(field.value, forKey: setKey)
            }
        }
        return newInstance
    }

    /****************************
     *  INSERT
     *
     *  @par entity: String, entity (table) name
     *  @par fields: [String:Any], an array of pairs of Attribute,Value
     *
     *  ret: NSManageObjext, the new instance or empty object in case of error
     *
    *****************************/

    func insert(entity: String, fields: [String:Any]) -> NSManagedObject
    {
        let newInstance = self.coreDataInsert(entity: entity, fields: fields)
        do 
        {
            try context.save()
            print(newInstance)
            return newInstance
        } catch {
            //errors managment
            print("Failed saving" + error.localizedDescription)
            return NSManagedObject()
        }
    }

    /****************************

     *  MULTI INSERT
     *
     *  @par entity: String, entity (table) name
     *  @par fields: [[String:Any]], an array of arrays of pairs of Attribute,Value
     *
     *  ret: NSManageObjext, array of new instance of entity, empty array in case of error
     *
     *  This function is for multiple insert (eg seeds a entity (table) from
     *  the response of an API). It saves the instances in the context all together,
     *  after all of them are generated; this because save the context is expensive.
     *
    *****************************/

    func multyInsert(entity: String, fields: [[String:Any]]) -> [NSManagedObject]
    {
        var instances = [NSManagedObject]()
       
        for field in fields
        {
            let newInstance = self.coreDataInsert(entity: entity, fields: field)
            instances.append(newInstance)
        }
        do 
        {
            try context.save()
            return instances
        } catch {
            print("Failed saving" + error.localizedDescription)
            return [NSManagedObject]()
        }
    }

    /****************************
     *  DELETE ALL DATA
     *
     *  @par entity: String, entity (table) name
     *
     *  ret: Bool, true for success, false otherwise
     *
     *  Remove all the data from a specific entity(table)
     *
    *****************************/
    
    func deleteAllData(entity: String) -> Bool
    {
        if(!self.entities.contains(entity))
        {
            return false
        }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        do
        {
            let results = try self.context.fetch(request)
            for managedObject in results
            {
                //print(managedObject)
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                self.context.delete(managedObjectData)
            }
            do 
            {
                try context.save()
                print("Delete all "+entity)
                return true
            } catch {
                print("Failed saving delete")
                return false
            }
        } catch let error as NSError {
            print("Detele all data in \(entity) error : \(error) \(error.userInfo)")
            return false
        }
    }
}
