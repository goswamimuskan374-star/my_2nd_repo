public with sharing class LeadRecordController {

    // ==========================
    // Get Lead Records
    // ==========================
    @AuraEnabled(cacheable=true)
    public static List<Lead> getLeads() {

        return [
            SELECT
                Id,
                Name,
                Company,
                Status,
                Phone,
                Email,
                CreatedDate
            FROM Lead
            ORDER BY CreatedDate DESC
            LIMIT 1000
        ];

    }

    // ==========================
    // Get Account Records
    // ==========================
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {

        return [
            SELECT
                Id,
                Name,
                Phone,
                Website,
                Industry,
                Type,
                CreatedDate
            FROM Account
            ORDER BY CreatedDate DESC
            LIMIT 1000
        ];

    }

}