public with sharing class BulkActionController {
    public class BulkActionData {
        @AuraEnabled public String label;
        @AuraEnabled public String parentObjectApiName;
        @AuraEnabled public String ObjectApiName;
        @AuraEnabled public String FieldApiName;
        @AuraEnabled public List<Map<String, Object>> unlinkedRecords;
        @AuraEnabled public List<Map<String, Object>> linkedRecords;
    }

    public class ActionResult {
        @AuraEnabled public Integer successCount = 0;
        @AuraEnabled public Integer failureCount = 0;
        @AuraEnabled public List<String> errors = new List<String>();
    }

    @AuraEnabled(cacheable=true)
    public static BulkActionData getBulkActionData(Id parentRecordId) {
        if (parentRecordId == null) {
            throw new AuraHandledException('Parent record Id are required.');
        }
        
        String objectApi = parentRecordId.getSObjectType().getDescribe().getName();
        Bulk_Action_Config__mdt config = getConfig(objectApi);

        String ObjectApiName = config.Object_API_Name__c;
        String FieldApiName = config.Field_API_Name__c;

        validateObjectAndField(objectApiName, fieldApiName);

        Schema.SObjectType childType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult childDescribe = childType.getDescribe();

        if (!childDescribe.isAccessible()) {
            throw new AuraHandledException('You do not have access to object: ' + objectApiName);
        }

        Map<String, Schema.SObjectField> childFields = childDescribe.fields.getMap();
        String displayField = getDisplayField(childFields);

        List<String> queryFields = new List<String>{ 'Id' };

        if (displayField != 'Id') {
            queryFields.add(displayField);
        }

        if (!queryFields.contains(fieldApiName)) {
            queryFields.add(fieldApiName);
        }

        String fieldList = String.join(queryFields, ', ');

        String unlinkedQuery =
            'SELECT ' + fieldList +
            ' FROM ' + objectApiName +
            ' WHERE ' + fieldApiName + ' = null' +
            ' ORDER BY LastModifiedDate DESC' +
            ' LIMIT 2000';

        String linkedQuery =
            'SELECT ' + fieldList +
            ' FROM ' + objectApiName +
            ' WHERE ' + fieldApiName + ' = :parentRecordId' +
            ' ORDER BY LastModifiedDate DESC' +
            ' LIMIT 2000';

        List<SObject> unlinkedRecords = Database.query(unlinkedQuery);
        List<SObject> linkedRecords = Database.query(linkedQuery);

        unlinkedRecords = Security.stripInaccessible(
            AccessType.READABLE,
            unlinkedRecords
        ).getRecords();

        linkedRecords = Security.stripInaccessible(
            AccessType.READABLE,
            linkedRecords
        ).getRecords();
        
        BulkActionData response = new BulkActionData();
        response.label = config.Label__c;
        response.parentObjectApiName = config.Parent_Object_API_Name__c;
        response.ObjectApiName = ObjectApiName;
        response.FieldApiName = FieldApiName;
        response.unlinkedRecords = toRows(unlinkedRecords, displayField, FieldApiName);
        response.linkedRecords = toRows(linkedRecords, displayField, FieldApiName);
        
        return response;
    }

    @AuraEnabled
    public static ActionResult bulkLink(
        List<Id> recordIds,
        String ObjectApiName,
        String FieldApiName,
        Id parentRecordId
    ) {
        if (recordIds == null || recordIds.isEmpty()) {
            throw new AuraHandledException('Select at least one record to link.');
        }

        if (parentRecordId == null) {
            throw new AuraHandledException('Parent record Id is required.');
        }

        return updateLookup(recordIds, ObjectApiName, FieldApiName, parentRecordId);
    }

    @AuraEnabled
    public static ActionResult bulkUnlink(
        List<Id> recordIds,
        String ObjectApiName,
        String FieldApiName
    ) {
        if (recordIds == null || recordIds.isEmpty()) {
            throw new AuraHandledException('Select at least one record to unlink.');
        }

        return updateLookup(recordIds, ObjectApiName, FieldApiName, null);
    }

    @AuraEnabled
    public static ActionResult bulkDelete(List<Id> recordIds, String ObjectApiName) {
        if (recordIds == null || recordIds.isEmpty()) {
            throw new AuraHandledException('Select at least one record to delete.');
        }

        if (String.isBlank(ObjectApiName)) {
            throw new AuraHandledException('object API name is required.');
        }

        if (!Schema.getGlobalDescribe().containsKey(ObjectApiName)) {
            throw new AuraHandledException('Invalid object API name: ' + ObjectApiName);
        }

        Schema.SObjectType childType = Schema.getGlobalDescribe().get(ObjectApiName);
        Schema.DescribeSObjectResult childDescribe = childType.getDescribe();

        if (!childDescribe.isDeletable()) {
            throw new AuraHandledException('You do not have delete access for: ' + ObjectApiName);
        }

        List<SObject> recordsToDelete = new List<SObject>();

        for (Id recordId : recordIds) {
            recordsToDelete.add(childType.newSObject(recordId));
        }

        Database.DeleteResult[] results = Database.delete(recordsToDelete, false);
        return buildDeleteResult(results);
    }

    private static ActionResult updateLookup(
        List<Id> recordIds,
        String ObjectApiName,
        String FieldApiName,
        Id parentRecordId
    ) {
        validateObjectAndField(ObjectApiName, FieldApiName);

        Schema.SObjectType childType = Schema.getGlobalDescribe().get(ObjectApiName);
        Schema.DescribeSObjectResult childDescribe = childType.getDescribe();

        if (!childDescribe.isUpdateable()) {
            throw new AuraHandledException('You do not have update access for: ' + ObjectApiName);
        }

        Schema.DescribeFieldResult lookupFieldDescribe =
            childDescribe.fields.getMap().get(FieldApiName).getDescribe();

        if (!lookupFieldDescribe.isUpdateable()) {
            throw new AuraHandledException('You do not have update access for field: ' + FieldApiName);
        }

        List<SObject> recordsToUpdate = new List<SObject>();

        for (Id recordId : recordIds) {
            SObject recordToUpdate = childType.newSObject(recordId);
            recordToUpdate.put(FieldApiName, parentRecordId);
            recordsToUpdate.add(recordToUpdate);
        }

        Database.SaveResult[] results = Database.update(recordsToUpdate, false);
        return buildSaveResult(results);
    }

    private static Bulk_Action_Config__mdt getConfig(String parentObjectApiName) {
        List<Bulk_Action_Config__mdt> configs = [
            SELECT Parent_Object_API_Name__c,
                   Object_API_Name__c,
                   Field_API_Name__c,
                   Label__c
            FROM Bulk_Action_Config__mdt
            WHERE Parent_Object_API_Name__c = :parentObjectApiName
            LIMIT 1
        ];

        if (configs.isEmpty()) {
            throw new AuraHandledException(
                'No Bulk Action Config found for parent object: ' + parentObjectApiName
            );
        }

        Bulk_Action_Config__mdt config = configs[0];

        if (
            String.isBlank(config.Object_API_Name__c) ||
            String.isBlank(config.Field_API_Name__c)
        ) {
            throw new AuraHandledException('Bulk Action Config is incomplete.');
        }

        return config;
    }

    private static void validateObjectAndField(String objectApiName, String fieldApiName) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        if (!globalDescribe.containsKey(objectApiName)) {
            throw new AuraHandledException('Invalid object API name: ' + objectApiName);
        }

        Map<String, Schema.SObjectField> fields =
            globalDescribe.get(objectApiName).getDescribe().fields.getMap();

        if (!fields.containsKey(fieldApiName)) {
            throw new AuraHandledException('Invalid field API name: ' + fieldApiName);
        }
    }

    private static String getDisplayField(Map<String, Schema.SObjectField> fields) {
        List<String> preferredFields = new List<String>{
            'Name',
            'Subject',
            'CaseNumber',
            'LastName',
            'Title'
        };

        for (String fieldName : preferredFields) {
            if (
                fields.containsKey(fieldName) &&
                fields.get(fieldName).getDescribe().isAccessible()
            ) {
                return fieldName;
            }
        }

        return 'Id';
    }

    private static List<Map<String, Object>> toRows(
        List<SObject> records,
        String displayField,
        String FieldApiName
    ) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();

        for (SObject recordItem : records) {
            Map<String, Object> row = new Map<String, Object>();
            Id recordId = (Id) recordItem.get('Id');

            row.put('Id', recordId);
            row.put('recordUrl', '/' + String.valueOf(recordId));
            row.put('displayValue', String.valueOf(recordItem.get(displayField)));
            row.put(FieldApiName, recordItem.get(FieldApiName));

            rows.add(row);
        }

        return rows;
    }

    private static ActionResult buildSaveResult(Database.SaveResult[] results) {
        ActionResult response = new ActionResult();

        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                response.successCount++;
            } else {
                response.failureCount++;

                for (Database.Error error : result.getErrors()) {
                    response.errors.add(error.getMessage());
                }
            }
        }

        return response;
    }

    private static ActionResult buildDeleteResult(Database.DeleteResult[] results) {
        ActionResult response = new ActionResult();

        for (Database.DeleteResult result : results) {
            if (result.isSuccess()) {
                response.successCount++;
            } else {
                response.failureCount++;

                for (Database.Error error : result.getErrors()) {
                    response.errors.add(error.getMessage());
                }
            }
        }

        return response;
    }
}