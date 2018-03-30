/**
 * @description This class is used to query Contact records.
 */
public class ContactsSelector {

    public static List<Contact> selectContactsWithPaymentsById(Set<Id> contactIds) {
        return [SELECT Id, Total_Payment__c, Number_of_Payments__c, Last_Payment_Date__c, Name, (SELECT Id, Name, Project__c, Project__r.Name, Amount__c, Payment_Date__c FROM Payments__r ORDER BY Payment_Date__c DESC, Project__r.Name) FROM Contact WHERE Id IN :contactIds AND Number_of_Payments__c > 0 ORDER BY Name];
    }

    public static List<Contact> selectContactsWithPayments() {
        return [SELECT Id, Total_Payment__c, Number_of_Payments__c, Last_Payment_Date__c, Name, (SELECT Id, Name, Project__c, Project__r.Name, Amount__c, Payment_Date__c FROM Payments__r ORDER BY Payment_Date__c DESC, Project__r.Name) FROM Contact WHERE Number_of_Payments__c > 0 ORDER BY Name];
    }
}