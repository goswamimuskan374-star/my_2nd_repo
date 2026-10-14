trigger Account on Account (After update) {
    map<Id, Integer> accMap = new map<Id, Integer> (); 
    List<AggregateResult> agrList = [SELECT accountId,COUNT(Id)Countdata FROM Contact WHERE AccountId IN : trigger.new group by accountId];
    for(AggregateResult agr : agrList){
        accMap.put((Id)agr.get('accountId'),(Integer)agr.get('Countdata'));
    }
    FOR(Account acc : trigger.new){
        if(accMap.get(acc.Id)>5){
          //  error
        }
    }
}