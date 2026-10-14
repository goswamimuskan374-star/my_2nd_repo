public with sharing class WorkTrackerController {

    @AuraEnabled(cacheable=true)
    public static List<Tracker__c> getMyRequirements() {

        String currentUsername = UserInfo.getUserName();

        return [
            SELECT
                Id,
                Name,
                Description__c,
                Assigned_to__c,
                Status__c,
                Started_On__c,
                Completed_On__c
            FROM Tracker__c
            WHERE Assigned_to__c = :currentUsername
            ORDER BY CreatedDate ASC
        ];
    }


    @AuraEnabled
    public static void startRequirement(Id requirementId) {

        Tracker__c tracker = [
            SELECT
                Id,
                Assigned_to__c,
                Status__c,
                Started_On__c
            FROM Tracker__c
            WHERE Id = :requirementId
            LIMIT 1
        ];

        String currentUsername = UserInfo.getUserName();

        if (tracker.Assigned_to__c != currentUsername) {
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
                Assigned_to__c,
                Status__c,
                Started_On__c,
                Completed_On__c
            FROM Tracker__c
            WHERE Id = :requirementId
            LIMIT 1
        ];

        String currentUsername = UserInfo.getUserName();

        if (tracker.Assigned_to__c != currentUsername) {
            throw new AuraHandledException(
                'You are not authorized to update this requirement.'
            );
        }

        tracker.Status__c = 'Completed';
        tracker.Completed_On__c = System.now();

        update tracker;
    }
}