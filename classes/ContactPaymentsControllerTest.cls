@isTest
private class ContactPaymentsControllerTest {

    @isTest
    private static void addNewPayment_expectIsAddingNewPaymentToBeTrue() {
        ContactPaymentsController controller = new ContactPaymentsController();

        System.assert(!controller.IsAddingNewPayment, 'Expected the new payment form toggle to be false.');

        controller.addNewPayment();

        System.assert(controller.IsAddingNewPayment, 'Expected the new payment form toggle to be true.');
    }

    @isTest
    private static void cancelNewPayment_addNewPaymentThenCancel_expectPaymentFormToggleToBeFalse() {
        ContactPaymentsController controller = new ContactPaymentsController();

        controller.addNewPayment();

        System.assert(controller.IsAddingNewPayment, 'Expected the new payment form toggle to be true.');

        controller.cancelNewPayment();

        System.assert(!controller.IsAddingNewPayment, 'Expected the new payment form toggle to be false.');
    }

    @isTest
    private static void saveNewPayment_createNewPaymentForContact_expectNewRecordInserted() {
        Contact testContact = TestDataUtil.insertContact();
        Project__c project = TestDataUtil.insertProject('Sample Project');

        TestDataUtil.insertPayment(testContact.Id, project.Id, 100, Date.today());

        ContactPaymentsController controller = new ContactPaymentsController();
        controller.ContactRecord = ContactsSelector.selectContactsWithPaymentsById(new Set<Id> { testContact.Id })[0];

        controller.addNewPayment();
        controller.NewPayment.Project__c = project.Id;
        controller.NewPayment.Amount__c = 500;
        controller.NewPayment.Payment_Date__c = Date.today();
        controller.NewPayment.Contact__c = testContact.Id;

        controller.saveNewPayment();

        System.assert(ApexPages.hasMessages(ApexPages.Severity.CONFIRM), 'Expected the page to have success messages.');

        System.assertEquals(2, controller.ContactRecord.Payments__r.size(), 'Expected the contact to have 2 payments now.');
    }

    @isTest
    private static void updatePayments_changePaymentAmount_expectPaymentRecordUpdated() {
        Contact testContact = TestDataUtil.insertContact();
        Project__c project = TestDataUtil.insertProject('Sample Project');

        Decimal originalAmount = 100;
        Decimal expectedAmount = 1000;

        TestDataUtil.insertPayment(testContact.Id, project.Id, originalAmount, Date.today());

        ContactPaymentsController controller = new ContactPaymentsController();
        controller.ContactRecord = ContactsSelector.selectContactsWithPaymentsById(new Set<Id> { testContact.Id })[0];

        controller.ContactRecord.Payments__r[0].Amount__c = expectedAmount;

        controller.updatePayments();

        System.assert(ApexPages.hasMessages(ApexPages.Severity.CONFIRM), 'Expected the page to have success messages.');

        Contact updatedContact = ContactsSelector.selectContactsWithPaymentsById(new Set<Id> { testContact.Id })[0];
        System.assertEquals(expectedAmount, updatedContact.Payments__r[0].Amount__c, 'Expected the payment amount to be updated.');
    }

    @isTest
    private static void deletePayment_deleteOnlyPaymentForContact_expectNoMorePayments() {
        Contact testContact = TestDataUtil.insertContact();
        Project__c project = TestDataUtil.insertProject('Sample Project');

        Payment__c payment = TestDataUtil.insertPayment(testContact.Id, project.Id, 100, Date.today());

        ContactPaymentsController controller = new ContactPaymentsController();
        controller.ContactRecord = ContactsSelector.selectContactsWithPaymentsById(new Set<Id> { testContact.Id })[0];

        controller.TargetPaymentId = payment.Id;

        controller.deletePayment();

        System.assert(ApexPages.hasMessages(ApexPages.Severity.CONFIRM), 'Expected the page to have success messages.');

        Contact updatedContact = [SELECT Id, (SELECT Id FROM Payments__r) FROM Contact WHERE Id = :testContact.Id LIMIT 1];
        System.assertEquals(0, updatedContact.Payments__r.size(), 'Expected no more payments for the contact.');
    }
}