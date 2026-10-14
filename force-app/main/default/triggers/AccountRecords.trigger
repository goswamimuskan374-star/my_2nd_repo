trigger AccountRecords on Account (After Update) {
    
    Set<Id> accIdSet = new Set<Id>();
    
    for(Account acc : Trigger.new) {
        
        Account oldAcc = Trigger.oldMap.get(acc.Id);
        
        if(oldAcc.OwnerId != acc.OwnerId) {
            accIdSet.add(acc.Id);
        }
    }
    
    Map<Id, String> accOwnerMap = new Map<Id, String>();
    
    List<Account> accList = [SELECT Id, Owner.Name FROM Account WHERE Id IN :accIdSet];
    for(Account acc : accList) {
        accOwnerMap.put(acc.Id, acc.Owner.Name);
    }
    
    List<Contact> conList = [SELECT Id, Name, AccountId, Description FROM Contact WHERE AccountId IN :accIdSet];
    for(Contact con : conList) {
        
        if(accOwnerMap.containsKey(con.AccountId)) {
            con.Description = accOwnerMap.get(con.AccountId);
        }
    } 
    
    if(!conList.isEmpty()) {
        update conList;
    }
}