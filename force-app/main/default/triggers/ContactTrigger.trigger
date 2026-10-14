trigger ContactTrigger on Contact (After Update) {
    List<task> tList = new List<task>();
    for(Contact con : trigger.new){
        Contact oldCon = trigger.oldMap.get(con.Id);
        if(oldCon.Department != 'Sales' && con.Department == 'Sales' && con.Email != null){
            task t = new task();
            t.Subject = 'Follow Up - Sales Contact';
            t.Status  = 'Not Started';
            t.Priority = 'High';
            t.WhoId = Con.Id;
            tList.add(t);
        }
    }
    if(!tList.isEmpty()){
        insert tList;
    }
}