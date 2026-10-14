public without sharing class AccountLazyLoader {

    @AuraEnabled
    public static List<Account> getAccounts(
        Integer offsetValue,
        Integer pageSize
    ) {
        List<Account> accList = [
            SELECT Id, Name, Phone, Website
            FROM Account
            ORDER BY CreatedDate DESC
            LIMIT :pageSize
            OFFSET :offsetValue
        ];

        System.debug('RETURNED = ' + accList.size());

        return accList;
    }
}