public class ContactName {
    
    public String nameData;
    public Integer numberOfContact;
    public Boolean isClosed;
    public Time timeCalculation;
    
    public ContactName(){
        nameData = 'hii Yashu';
        numberOfContact = 88;
        isClosed = true;
        system.debug('all debug data ->>>>>---'+nameData+'   '+'   '+numberOfContact+'   '+'   '+isClosed);
        list<Contact> conList = [Select ID,Name FROM Contact LIMIT 400];
        system.debug('conList ->>>>>---'+conList);
    }
}