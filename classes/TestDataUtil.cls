/**
 * @description Used to generate data for unit tests
 */
@isTest
public class TestDataUtil {

    public static Contact insertContact() {
        Integer randomInt = Integer.valueOf(Math.random());

        Contact newRecord = new Contact();
        newRecord.Email = 'testEmail' + randomInt + '@test.com';
        newRecord.FirstName = 'First' + randomInt;
        newRecord.LastName = 'Last' + randomInt;

        insert newRecord;

        return newRecord;
    }

    public static Project__c insertProject(String projectName) {
        Project__c newProject = new Project__c();
        newProject.Name = projectName;

        insert newProject;

        return newProject;
    }

    public static Payment__c createPayment(Id contactId, Id projectId, Decimal paymentAmount, Date paymentDate) {
        Payment__c newPayment = new Payment__c();
        newPayment.Contact__c = contactId;
        newPayment.Project__c = projectId;
        newPayment.Amount__c = paymentAmount;
        newPayment.Payment_Date__c = paymentDate;

        return newPayment;
    }

    public static Payment__c insertPayment(Id contactId, Id projectId, Decimal paymentAmount, Date paymentDate) {
        Payment__c newPayment = createPayment(contactId, projectId, paymentAmount, paymentDate);

        insert newPayment;

        return newPayment;
    }

    public static List<Payment__c> insertPayments(Id contactId, Id projectId, Decimal paymentAmount, Date paymentDate, Integer numberToInsert) {
        List<Payment__c> newPayments = new List<Payment__c>();

        for (Integer i = 0; i < numberToInsert; i++) {
            newPayments.add(createPayment(contactId, projectId, paymentAmount, paymentDate));
        }

        if (!newPayments.isEmpty()) {
            insert newPayments;
        }

        return newPayments;
    }
}