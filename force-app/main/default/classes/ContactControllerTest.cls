@IsTest
private class ContactControllerTest {

    @TestSetup
    static void createTestData() {
        List<Contact> contacts = new List<Contact>();

        for(Integer i = 1; i <= 5; i++) {
            contacts.add(new Contact(
                LastName = 'Test Contact ' + i,
                Email = 'test' + i + '@example.com',
                Phone = '1234567890'
            ));
        }

        insert contacts;
    }

    @IsTest
    static void testGetContacts() {

        Test.startTest();

        List<Contact> result = ContactController.getContacts();

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.size() > 0);
        System.assertEquals('Test Contact 1', result[0].LastName);
    }
}