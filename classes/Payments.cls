/**
 * @description Payments domain class to handle trigger events and certain aggregate functions on collections of payment records.
 */
public class Payments {

    private List<Payment__c> records;

    public Payments(List<Payment__c> paymentRecords) {
        this.records = paymentRecords;
    }

    public void onAfterInsert() {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();
        for (Payment__c record : this.records) {
            contactIds.add(record.Contact__c);
            projectIds.add(record.Project__c);
        }

        PaymentRollupService.Instance.updateRollups(contactIds, projectIds);
    }

    public void onAfterUpdate(Map<Id, Payment__c> existingPaymentsById) {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();
        for (Payment__c record : this.records) {
            Payment__c originalRecord = existingPaymentsById.get(record.Id);

            if (shouldUpdateContactRollups(record, originalRecord)) {
                contactIds.add(record.Contact__c);
            }

            if (shouldUpdateProjectRollups(record, originalRecord)) {
                projectIds.add(record.Project__c);
            }
        }

        PaymentRollupService.Instance.updateRollups(contactIds, projectIds);
    }

    public void onAfterDelete() {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();
        for (Payment__c record : this.records) {
            contactIds.add(record.Contact__c);
            projectIds.add(record.Project__c);
        }

        PaymentRollupService.Instance.updateRollups(contactIds, projectIds);
    }

    public AggregateData getAggregateData() {
        Decimal sumOfAllPayments = 0;
        Date mostRecentPaymentDate;
        for (Payment__c paymentRecord : this.records) {
            if (paymentRecord.Amount__c != null) {
                sumOfAllPayments += paymentRecord.Amount__c;
            }

            // If the mostRecentPaymentDate is null, we havent't found a date yet get the value from the current record.
            // Otherwise, see if the current record is more recent than our current date value.
            if (mostRecentPaymentDate == null) {
                mostRecentPaymentDate = paymentRecord.Payment_Date__c;
            } else if (paymentRecord.Payment_Date__c != null && (mostRecentPaymentDate < paymentRecord.Payment_Date__c)) {
                mostRecentPaymentDate = paymentRecord.Payment_Date__c;
            }
        }

        return new AggregateData(sumOfAllPayments, mostRecentPaymentDate, this.records.size());
    }

    private Boolean shouldUpdateContactRollups(Payment__c newPayment, Payment__c originalPayment) {
        if (originalPayment == null || newPayment == null) {
            return false;
        }

        // Return true if either the amount of payment date changed.
        return (newPayment.Amount__c != originalPayment.Amount__c) ||
                (newPayment.Payment_Date__c != originalPayment.Payment_Date__c);
    }

    private Boolean shouldUpdateProjectRollups(Payment__c newPayment, Payment__c originalPayment) {
        if (originalPayment == null || newPayment == null) {
            return false;
        }

        // Return true if the amount changed.
        return (newPayment.Amount__c != originalPayment.Amount__c);
    }

    public static void handleTrigger() {
        // For the scope of this exercise we don't no stinkin' before triggers so return early.
        if (Trigger.isBefore) {
            return;
        }

        // If this is a delete trigger, create the domain class from the oldMap of records since that is all we have.
        // Otherwise, create it from the new records
        Payments paymentsDomain = Trigger.isDelete ? new Payments(Trigger.oldMap.values()) : new Payments(Trigger.new);

        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                paymentsDomain.onAfterInsert();
            } else if (Trigger.isUpdate) {
                paymentsDomain.onAfterUpdate((Map<Id, Payment__c>)Trigger.oldMap);
            } else if (Trigger.isDelete) {
                paymentsDomain.onAfterDelete();
            }
        }
    }

    /**
     * @description This class is used to provide aggregate information on a collection of payment records.
     */
    public class AggregateData {

        public Integer NumberOfPayments { get; private set; }

        public Date LatestPaymentDate { get; private set; }

        public Decimal TotalPayment { get; private set; }

        public AggregateData(Decimal sumOfAllPayments, Date mostRecentPaymentDate, Integer numberOfRecords) {
            this.LatestPaymentDate = mostRecentPaymentDate;
            this.TotalPayment = sumOfAllPayments;
            this.NumberOfPayments = numberOfRecords;
        }
    }
}