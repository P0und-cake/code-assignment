@isTest
private class PaymentsControllerTest {

    @isTest
    private static void getContacts_noContactsWithPayments_expectEmptyList() {
        // Insert a contact and a project but don't insert any payments.
        TestDataUtil.insertContact();
        TestDataUtil.insertProject('Sample Project');

        PaymentsController controller = new PaymentsController();

        Test.startTest();
        List<Contact> contacts = controller.getContacts();
        Test.stopTest();

        System.assertEquals(0, contacts.size(), 'No contacts should have been loaded by the page.');
        System.assert(!controller.getHasContacts(), 'No contacts should have been loaded by the page.');
    }

    @isTest
    private static void getContacts_contactsWithPayments_expectContactsQueried() {
        // Insert a contact and a project then insert payments.
        Contact testContact = TestDataUtil.insertContact();
        Project__c project = TestDataUtil.insertProject('Sample Project');

        TestDataUtil.insertPayments(testContact.Id, project.Id, 100, Date.today(), 4);

        PaymentsController controller = new PaymentsController();

        Test.startTest();
        List<Contact> contacts = controller.getContacts();
        Test.stopTest();

        System.assertEquals(1, contacts.size(), 'Expected a contact to be retrieved by the page.');
        System.assert(controller.getHasContacts(), 'A contact should have been loaded by the page.');
    }
}