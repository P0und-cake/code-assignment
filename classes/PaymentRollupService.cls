/**
 * @description This class is used to calculate rollups on the Payment's parent objects: Contact, Project. It is called from the Payment trigger after delete, after insert, and after update.
 */
public class PaymentRollupService {

    private PaymentRollupService() { }

    public void updateRollups(Set<Id> contactIds, Set<Id> projectIds) {
        updateContactRollups(contactIds);
        updateProjectRollups(projectIds);
    }

    public void updateContactRollups(Set<Id> contactIds) {
        if (contactIds == null || contactIds.isEmpty()) {
            return;
        }

        List<Contact> contactsWithPayments = [SELECT Id, Name, Total_Payment__c, Last_Payment_Date__c, Number_of_Payments__c, (SELECT Id, Amount__c, Payment_Date__c FROM Payments__r) FROM Contact WHERE Id IN :contactIds FOR UPDATE];

        Map<Id, Contact> contactsToUpdateById = new Map<Id, Contact>();

        for (Contact contactRecord : contactsWithPayments) {
            Contact contactToUpdate = updateRollupsForContact(contactRecord);

            if (contactToUpdate != null) {
                contactsToUpdateById.put(contactToUpdate.Id, contactToUpdate);
            }
        }

        if (!contactsToUpdateById.isEmpty()) {
            update contactsToUpdateById.values();
        }
    }

    public void updateProjectRollups(Set<Id> projectIds) {
        if (projectIds == null || projectIds.isEmpty()) {
            return;
        }

        List<Project__c> projectsWithPayments = [SELECT Id, Name, Total_Payment__c, Number_of_Payments__c, (SELECT Id, Amount__c, Payment_Date__c FROM Payments__r) FROM Project__c WHERE Id IN :projectIds FOR UPDATE];

        Map<Id, Project__c> projectsToUpdateById = new Map<Id, Project__c>();

        for (Project__c projectRecord : projectsWithPayments) {
            Project__c projectToUpdate = updateRollupsForProject(projectRecord);

            if (projectToUpdate != null) {
                projectsToUpdateById.put(projectToUpdate.Id, projectToUpdate);
            }
        }

        if (!projectsToUpdateById.isEmpty()) {
            update projectsToUpdateById.values();
        }
    }

    // Returns a record if there are any changes.
    private Contact updateRollupsForContact(Contact contactWithPayments) {
        Payments paymentsDomain = new Payments(contactWithPayments.Payments__r);
        Payments.AggregateData paymentData = paymentsDomain.getAggregateData();

        // Only return a record to update if there are actually changes to make.
        if (paymentData.TotalPayment != contactWithPayments.Total_Payment__c ||
                paymentData.LatestPaymentDate != contactWithPayments.Last_Payment_Date__c ||
                paymentData.NumberOfPayments != contactWithPayments.Number_of_Payments__c) {
            return new Contact(Id = contactWithPayments.Id,
                    Total_Payment__c = paymentData.TotalPayment,
                    Last_Payment_Date__c = paymentData.LatestPaymentDate,
                    Number_of_Payments__c = paymentData.NumberOfPayments);
        }

        return null;
    }

    // Returns a record if there are any changes.
    private Project__c updateRollupsForProject(Project__c projectWithPayments) {
        Payments paymentsDomain = new Payments(projectWithPayments.Payments__r);
        Payments.AggregateData paymentData = paymentsDomain.getAggregateData();

        // Only return a record to update if there are actually changes to make.
        if (paymentData.TotalPayment != projectWithPayments.Total_Payment__c ||
                paymentData.NumberOfPayments != projectWithPayments.Number_of_Payments__c) {
            return new Project__c(Id = projectWithPayments.Id,
                    Total_Payment__c = paymentData.TotalPayment,
                    Number_of_Payments__c = paymentData.NumberOfPayments);
        }

        return null;
    }

    public static PaymentRollupService Instance {
        get {
            if (Instance == null) {
                Instance = new PaymentRollupService();
            }
            return Instance;
        }
        private set;
    }
}