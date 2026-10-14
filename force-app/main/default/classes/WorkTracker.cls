public with sharing class WorkTracker {

    @AuraEnabled(cacheable=true)
    public static List<Tracker__c> getMyRequirements() {

        String currentUserName = UserInfo.getName();

        return [
            SELECT
                Id,
                Name,
                Description__c,
                Assigned_To__c,
                Status__c,
                Started_On__c,
                Completed_On__c
            FROM Tracker__c
            WHERE Assigned_To__c = :currentUserName
            ORDER BY CreatedDate ASC
        ];
    }


    @AuraEnabled
    public static void startRequirement(Id requirementId) {

        Tracker__c tracker = [
            SELECT
                Id,
                Assigned_To__c,
                Status__c,
                Started_On__c
            FROM Tracker__c
            WHERE Id = :requirementId
            LIMIT 1
        ];

        if (tracker.Assigned_To__c != UserInfo.getName()) {
            throw new AuraHandledException(
                'You are not authorized to update this requirement.'
            );
        }

        tracker.Status__c = 'In Progress';
        tracker.Started_On__c = System.now();

        update tracker;
    }


    @AuraEnabled
    public static void completeRequirement(Id requirementId) {

        Tracker__c tracker = [
            SELECT
                Id,
                Assigned_To__c,
                Status__c,
                Started_On__c,
                Completed_On__c
            FROM Tracker__c
            WHERE Id = :requirementId
            LIMIT 1
        ];

        if (tracker.Assigned_To__c != UserInfo.getName()) {
            throw new AuraHandledException(
                'You are not authorized to update this requirement.'
            );
        }

        tracker.Status__c = 'Completed';
        tracker.Completed_On__c = System.now();

        update tracker;
    }
}