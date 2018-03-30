@isTest
private class PaymentsTest {

    private static Contact insertContact() {
        Integer randomInt = Integer.valueOf(Math.random());

        Contact newRecord = new Contact();
        newRecord.Email = 'testEmail' + randomInt + '@test.com';
        newRecord.FirstName = 'First' + randomInt;
        newRecord.LastName = 'Last' + randomInt;

        insert newRecord;

        return newRecord;
    }

    private static Project__c insertProject(String projectName) {
        Project__c newProject = new Project__c();
        newProject.Name = projectName;

        insert newProject;

        return newProject;
    }

    private static Payment__c createPayment(Id contactId, Id projectId, Decimal paymentAmount, Date paymentDate) {
        Payment__c newPayment = new Payment__c();
        newPayment.Contact__c = contactId;
        newPayment.Project__c = projectId;
        newPayment.Amount__c = paymentAmount;
        newPayment.Payment_Date__c = paymentDate;

        return newPayment;
    }

    private static Payment__c insertPayment(Id contactId, Id projectId, Decimal paymentAmount, Date paymentDate) {
        Payment__c newPayment = createPayment(contactId, projectId, paymentAmount, paymentDate);

        insert newPayment;

        return newPayment;
    }

    private static List<Payment__c> insertPayments(Id contactId, Id projectId, Decimal paymentAmount, Date paymentDate, Integer numberToInsert) {
        List<Payment__c> newPayments = new List<Payment__c>();

        for (Integer i = 0; i < numberToInsert; i++) {
            newPayments.add(createPayment(contactId, projectId, paymentAmount, paymentDate));
        }

        if (!newPayments.isEmpty()) {
            insert newPayments;
        }

        return newPayments;
    }

    private static Contact selectContactById(Id contactId) {
        return [SELECT Id, Last_Payment_Date__c, Total_Payment__c FROM Contact WHERE Id = :contactId LIMIT 1];
    }

    private static Project__c selectProjectById(Id projectId) {
        return [SELECT Id, Total_Payment__c, Number_of_Payments__c FROM Project__c WHERE Id = :projectId LIMIT 1];
    }

    private static void assertContactRollups(Id contactId, Decimal expectedTotalPaymentAmount, Date expectedLatestPaymentDate) {
        Contact contactToAssert = selectContactById(contactId);

        System.assertEquals(expectedTotalPaymentAmount, contactToAssert.Total_Payment__c,
                'Expected the contact to be updated with the sum of all payments.');
        System.assertEquals(expectedLatestPaymentDate, contactToAssert.Last_Payment_Date__c,
                'Expected the contact to be updated with the latest payment date.');
    }

    private static void assertProjectRollups(Id projectId, Decimal expectedTotalPaymentAmount) {
        Project__c projectToAssert = selectProjectById(projectId);

        System.assertEquals(expectedTotalPaymentAmount, projectToAssert.Total_Payment__c,
                'Expected the project to be updated with the sum of all payments.');
    }

    @isTest
    private static void onAfterInsert_newPaymentInsertedForContact_contactHasNoPayments_expectRollupsUpdated() {
        String projectName = 'Presence Needs A New Dev';

        Decimal newPaymentAmount = 1500;
        Date newPaymentDate = Date.today().addDays(-10);

        Decimal expectedTotalPaymentAmount = 1500;
        Date expectedLatestPaymentDate = newPaymentDate;

        Project__c project = TestDataUtil.insertProject(projectName);
        Contact testContact = TestDataUtil.insertContact();

        Test.startTest();
        Payment__c testPayment1 = TestDataUtil.insertPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);
        Test.stopTest();

        assertContactRollups(testContact.Id, expectedTotalPaymentAmount, newPaymentDate);
        assertProjectRollups(project.Id, expectedTotalPaymentAmount);
    }

    @isTest
    private static void onAfterInsert_newPaymentsInsertedForContact_contactAndProjectHaveExistingPayments_expectRollupsUpdated() {
        String projectName = 'Presence Needs A New Dev';

        Decimal newPaymentAmount = 500;
        Date newPaymentDate = Date.today().addDays(-10);

        Decimal expectedTotalPaymentAmount = 1500;
        Date expectedLatestPaymentDate = Date.today();

        Project__c project = TestDataUtil.insertProject(projectName);
        Contact testContact = TestDataUtil.insertContact();

        Payment__c testPayment1 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment2 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, expectedLatestPaymentDate);
        Payment__c testPayment3 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);

        Test.startTest();
        insert new List<Payment__c> { testPayment1, testPayment2, testPayment3 };
        Test.stopTest();

        assertContactRollups(testContact.Id, expectedTotalPaymentAmount, expectedLatestPaymentDate);
        assertProjectRollups(project.Id, expectedTotalPaymentAmount);
    }

    @isTest
    private static void onAfterUpdate_paymentAmountUpdatedForContact_expectRollupsUpdated() {
        String projectName = 'Presence Needs A New Dev';

        Decimal newPaymentAmount = 500;
        Decimal updatedPaymentAmount = 100;
        Date newPaymentDate = Date.today().addDays(-10);

        Decimal expectedTotalPaymentAmount = 1100;

        Project__c project = TestDataUtil.insertProject(projectName);
        Contact testContact = TestDataUtil.insertContact();

        // Insert the 3 payments that should add up to 1500;
        Payment__c testPayment1 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment2 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment3 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);

        insert new List<Payment__c> { testPayment1, testPayment2, testPayment3 };

        assertContactRollups(testContact.Id, 1500, newPaymentDate);
        assertProjectRollups(project.Id, 1500);

        Test.startTest();
        // Now update one of the payments so we can see if this is reflected in the contact record.
        testPayment3.Amount__c = updatedPaymentAmount;
        update testPayment3;
        Test.stopTest();

        assertContactRollups(testContact.Id, expectedTotalPaymentAmount, newPaymentDate);
        assertProjectRollups(project.Id, expectedTotalPaymentAmount);
    }

    @isTest
    private static void onAfterUpdate_paymentDateUpdatedForContact_expectRollupsUpdated() {
        String projectName = 'Presence Needs A New Dev';

        Decimal newPaymentAmount = 500;
        Date newPaymentDate = Date.today().addDays(-10);
        Date updatedPaymentDate = Date.today();

        Decimal expectedTotalPaymentAmount = 1500;
        Date expectedLatestPaymentDate = updatedPaymentDate;

        Project__c project = TestDataUtil.insertProject(projectName);
        Contact testContact = TestDataUtil.insertContact();

        // Insert the 3 payments that should add up to 1500;
        Payment__c testPayment1 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment2 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment3 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);

        insert new List<Payment__c> { testPayment1, testPayment2, testPayment3 };

        assertContactRollups(testContact.Id, expectedTotalPaymentAmount, newPaymentDate);
        assertProjectRollups(project.Id, expectedTotalPaymentAmount);

        Test.startTest();
        // Now update one of the payments so we can see if this is reflected in the contact record.
        testPayment3.Payment_Date__c = updatedPaymentDate;
        update testPayment3;
        Test.stopTest();

        assertContactRollups(testContact.Id, expectedTotalPaymentAmount, expectedLatestPaymentDate);
        assertProjectRollups(project.Id, expectedTotalPaymentAmount);
    }

    @isTest
    private static void onAfterUpdate_paymentDateAndAmountUpdatedForContact_expectRollupsUpdated() {
        String projectName = 'Presence Needs A New Dev';

        Decimal newPaymentAmount = 500;
        Decimal updatedPaymentAmount = 100;
        Date newPaymentDate = Date.today().addDays(-10);
        Date updatedPaymentDate = Date.today();

        Decimal expectedTotalPaymentAmount = 1100;
        Date expectedLatestPaymentDate = updatedPaymentDate;

        Project__c project = TestDataUtil.insertProject(projectName);
        Contact testContact = TestDataUtil.insertContact();

        // Insert the 3 payments that should add up to 1500;
        Payment__c testPayment1 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment2 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment3 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);

        insert new List<Payment__c> { testPayment1, testPayment2, testPayment3 };

        assertContactRollups(testContact.Id, 1500, newPaymentDate);
        assertProjectRollups(project.Id, 1500);

        Test.startTest();
        // Now update one of the payments with a new date and one with a new amount so we can see if this is reflected in the contact record.
        testPayment2.Amount__c = updatedPaymentAmount;
        testPayment3.Payment_Date__c = updatedPaymentDate;
        update new List<Payment__c> { testPayment2, testPayment3 };
        Test.stopTest();

        assertContactRollups(testContact.Id, expectedTotalPaymentAmount, expectedLatestPaymentDate);
        assertProjectRollups(project.Id, expectedTotalPaymentAmount);
    }

    @isTest
    private static void onAfterDelete_paymentDeletedForContact_expectRollupsUpdated() {
        String projectName = 'Presence Needs A New Dev';

        Decimal newPaymentAmount = 500;
        Decimal updatedPaymentAmount = 100;
        Date newPaymentDate = Date.today().addDays(-10);

        Decimal expectedTotalPaymentAmount = 1000;
        Date expectedLatestPaymentDate = newPaymentDate;

        Project__c project = TestDataUtil.insertProject(projectName);
        Contact testContact = TestDataUtil.insertContact();

        // Insert the 3 payments that should add up to 1500;
        Payment__c testPayment1 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment2 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment3 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);

        insert new List<Payment__c> { testPayment1, testPayment2, testPayment3 };

        assertContactRollups(testContact.Id, 1500, expectedLatestPaymentDate);
        assertProjectRollups(project.Id, 1500);

        Test.startTest();
        // Now delete one of the payments so we can see if this is reflected in the contact record.
        delete testPayment3;
        Test.stopTest();

        assertContactRollups(testContact.Id, expectedTotalPaymentAmount, expectedLatestPaymentDate);
        assertProjectRollups(project.Id, expectedTotalPaymentAmount);
    }

    @isTest
    private static void onAfterDelete_allPaymentsDeletedForContact_expectRollupsToBeCleared() {
        String projectName = 'Presence Needs A New Dev';

        Decimal newPaymentAmount = 500;
        Decimal updatedPaymentAmount = 100;
        Date newPaymentDate = Date.today().addDays(-10);

        Decimal expectedTotalPaymentAmount = 0;
        Date expectedLatestPaymentDate = null;

        Project__c project = TestDataUtil.insertProject(projectName);
        Contact testContact = TestDataUtil.insertContact();

        // Insert the 3 payments that should add up to 1500;
        Payment__c testPayment1 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment2 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment3 = TestDataUtil.createPayment(testContact.Id, project.Id, newPaymentAmount, newPaymentDate);

        insert new List<Payment__c> { testPayment1, testPayment2, testPayment3 };

        assertContactRollups(testContact.Id, 1500, newPaymentDate);
        assertProjectRollups(project.Id, 1500);

        Test.startTest();
        // Now delete all of the payments so we can see if this is reflected in the contact record.
        delete new List<Payment__c> { testPayment1, testPayment2, testPayment3 };
        Test.stopTest();

        assertContactRollups(testContact.Id, expectedTotalPaymentAmount, expectedLatestPaymentDate);
        assertProjectRollups(project.Id, expectedTotalPaymentAmount);
    }

    @isTest
    private static void onAfterInsert_multipleContact_paymentsToMultipleProjects_expectRollupsCorrect() {
        String projectName1 = 'Presence Needs a New Dev';
        String projectName2 = 'Hire Zach Field';

        Decimal newPaymentAmount = 500;
        Date newPaymentDate = Date.today().addDays(-10);

        Date expectedPaymentDate = newPaymentDate;
        Decimal project1ExpectedTotal = 1000;
        Decimal project2ExpectedTotal = 1000;
        Decimal expectedTotalForContact1 = 1000;
        Decimal expectedTotalForContact2 = 1000;

        // Insert multiple projects.
        Project__c project1 = TestDataUtil.insertProject(projectName1);
        Project__c project2 = TestDataUtil.insertProject(projectName2);

        // Insert the contacts that will make payments to multiple projects.
        Contact testContact = TestDataUtil.insertContact();
        Contact testContact2 = TestDataUtil.insertContact();

        // Insert the payments. Each contact will make a payment of 500 to each project.
        Payment__c testPayment1 = TestDataUtil.createPayment(testContact.Id, project1.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment2 = TestDataUtil.createPayment(testContact.Id, project2.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment3 = TestDataUtil.createPayment(testContact2.Id, project1.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment4 = TestDataUtil.createPayment(testContact2.Id, project2.Id, newPaymentAmount, newPaymentDate);

        Test.startTest();
        insert new List<Payment__c> { testPayment1, testPayment2, testPayment3, testPayment4 };
        Test.stopTest();

        assertContactRollups(testContact.Id, expectedTotalForContact1, expectedPaymentDate);
        assertProjectRollups(project1.Id, project1ExpectedTotal);
        assertContactRollups(testContact2.Id, expectedTotalForContact2, expectedPaymentDate);
        assertProjectRollups(project2.Id, project2ExpectedTotal);
    }

    @isTest
    private static void onAfterUpdate_multipleContacts_paymentsToMultipleProjects_paymentForEachProjectUpdated_expectRollupsCorrect() {
        String projectName1 = 'Presence Needs a New Dev';
        String projectName2 = 'Hire Zach Field';

        Decimal newPaymentAmount = 500;
        Date newPaymentDate = Date.today().addDays(-10);
        Decimal updatedPaymentAmount = 250;

        Date expectedPaymentDate = newPaymentDate;
        Decimal project1OriginalTotal = 1000;
        Decimal project1ExpectedTotal = 750;
        Decimal project2OriginalTotal = 1000;
        Decimal project2ExpectedTotal = 500;
        Decimal originalTotalForContacts = 1000;
        Decimal expectedTotalForContact1 = 750;
        Decimal expectedTotalForContact2 = 500;

        // Insert multiple projects.
        Project__c project1 = TestDataUtil.insertProject(projectName1);
        Project__c project2 = TestDataUtil.insertProject(projectName2);

        // Insert the contacts that will make payments to multiple projects.
        Contact testContact = TestDataUtil.insertContact();
        Contact testContact2 = TestDataUtil.insertContact();

        // Insert the payments. Each contact will make a payment of 500 to each project.
        Payment__c testPayment1 = TestDataUtil.createPayment(testContact.Id, project1.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment2 = TestDataUtil.createPayment(testContact.Id, project2.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment3 = TestDataUtil.createPayment(testContact2.Id, project1.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment4 = TestDataUtil.createPayment(testContact2.Id, project2.Id, newPaymentAmount, newPaymentDate);

        List<Payment__c> payments = new List<Payment__c> { testPayment1, testPayment2, testPayment3, testPayment4 };
        insert payments;

        assertContactRollups(testContact.Id, originalTotalForContacts, expectedPaymentDate);
        assertContactRollups(testContact2.Id, originalTotalForContacts, expectedPaymentDate);
        assertProjectRollups(project1.Id, project1OriginalTotal);
        assertProjectRollups(project2.Id, project2OriginalTotal);

        Test.startTest();
        // Three of the four payments with the updated amount of 250.
        testPayment2.Amount__c = updatedPaymentAmount;
        testPayment3.Amount__c = updatedPaymentAmount;
        testPayment4.Amount__c = updatedPaymentAmount;
        update payments;
        Test.stopTest();

        assertContactRollups(testContact.Id, expectedTotalForContact1, expectedPaymentDate);
        assertContactRollups(testContact2.Id, expectedTotalForContact2, expectedPaymentDate);
        assertProjectRollups(project1.Id, project1ExpectedTotal);
        assertProjectRollups(project2.Id, project2ExpectedTotal);
    }

    @isTest
    private static void onAfterDelete_multipleContacts_paymentsToMultipleProjects_paymentsForOneContactDeleted_expectRollupsCorrect() {
        String projectName1 = 'Presence Needs a New Dev';
        String projectName2 = 'Hire Zach Field';

        Decimal newPaymentAmount = 500;
        Date newPaymentDate = Date.today().addDays(-10);
        Decimal updatedPaymentAmount = 250;

        Date expectedPaymentDate = newPaymentDate;
        Decimal project1OriginalTotal = 1000;
        Decimal project1ExpectedTotal = 500;
        Decimal project2OriginalTotal = 1000;
        Decimal project2ExpectedTotal = 500;
        Decimal originalTotalForContacts = 1000;
        Decimal expectedTotalForContact1 = 1000;
        Decimal expectedTotalForContact2 = 0;

        // Insert multiple projects.
        Project__c project1 = TestDataUtil.insertProject(projectName1);
        Project__c project2 = TestDataUtil.insertProject(projectName2);

        // Insert the contacts that will make payments to multiple projects.
        Contact testContact = TestDataUtil.insertContact();
        Contact testContact2 = TestDataUtil.insertContact();

        // Insert the payments. Each contact will make a payment of 500 to each project.
        Payment__c testPayment1 = TestDataUtil.createPayment(testContact.Id, project1.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment2 = TestDataUtil.createPayment(testContact.Id, project2.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment3 = TestDataUtil.createPayment(testContact2.Id, project1.Id, newPaymentAmount, newPaymentDate);
        Payment__c testPayment4 = TestDataUtil.createPayment(testContact2.Id, project2.Id, newPaymentAmount, newPaymentDate);

        List<Payment__c> payments = new List<Payment__c> { testPayment1, testPayment2, testPayment3, testPayment4 };
        insert payments;

        assertContactRollups(testContact.Id, originalTotalForContacts, expectedPaymentDate);
        assertContactRollups(testContact2.Id, originalTotalForContacts, expectedPaymentDate);
        assertProjectRollups(project1.Id, project1OriginalTotal);
        assertProjectRollups(project2.Id, project2OriginalTotal);

        Test.startTest();
        // Now delete the payments for contact 2.
        delete new List<Payment__c> { testPayment3, testPayment4 };
        Test.stopTest();

        assertContactRollups(testContact.Id, expectedTotalForContact1, expectedPaymentDate);
        assertContactRollups(testContact2.Id, expectedTotalForContact2, null);
        assertProjectRollups(project1.Id, project1ExpectedTotal);
        assertProjectRollups(project2.Id, project2ExpectedTotal);
    }
}