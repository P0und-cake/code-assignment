trigger Payments on Payment__c (after insert, after update, after delete) {
    Payments.handleTrigger();
}