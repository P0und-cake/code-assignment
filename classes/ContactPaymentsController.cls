/**
 * @description This is the controller for the ContactPayments.component which displays payment data for a single contact
*               and can be used to add new payments or delete existing payments..
 */
public with sharing class ContactPaymentsController {

    /**
     * @description The Contact record of focus.
     */
    public Contact ContactRecord { get; set; }

    /**
     * @description The Id of a payment to delete. This is used to store the value passed by our commandLink
     *              which specifies the payment to delete.
     */
    public String TargetPaymentId { get; set; }

    /**
     * @description A new payment that will be added for the contact.
     */
    public Payment__c NewPayment {
        get {
            if (NewPayment == null) {
                NewPayment = new Payment__c(Contact__c = ContactRecord.Id);
            }
            return NewPayment;
        }
        set;
    }

    /**
     * @description A toggle used to control whether or not the new payment form is added.
     */
    public Boolean IsAddingNewPayment {
        get { return IsAddingNewPayment == null ? false : IsAddingNewPayment; }
        set;
    }

    /**
     * @description Used to open the new payment form for the contact.
     */
    public void addNewPayment() {
        IsAddingNewPayment = true;
    }

    /**
     * @description Used to cancel the addition of a new payment. This also clears out the New Payment record.
     */
    public void cancelNewPayment() {
        IsAddingNewPayment = false;
        NewPayment = null;
    }

    /**
     * @description Saves the new payment record and closes the new payment form. If there are any exceptions they are
     *              displayed to the user. If the operation completes successfully, a success message is displayed.
     */
    public void saveNewPayment() {
        // First try to insert the new Payment. If there are any errors display them to the user.
        try {
            insert NewPayment;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error saving your new payment: ' + ex.getMessage()));
            return;
        }

        // Now refresh the contact data so that the user sees the new payment.
        try {
            IsAddingNewPayment = false;
            NewPayment = null;
            refreshData();

            ApexPages.currentPage().getParameters().put('refresh', 'true');

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Success! The new payment was added.'));
            return;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The new payment was added but there was an issue retrieving the updated data. Error Details: ' + ex.getMessage()));
            return;
        }
    }

    private Map<Id, Payment__c> getPaymentsById() {
        // Make sure we never return a null map even if the contact record is null for some reason.
        if (ContactRecord == null) {
            return new Map<Id, Payment__c>();
        }

        // We don't store this just to avoid extra view state and to make sure we don't have stale data.
        return new Map<Id, Payment__c>(ContactRecord.Payments__r);
    }

    private Payment__c getPaymentById(Id paymentId) {
        return getPaymentsById().get(paymentId);
    }

    /**
     * @description Used to update payments and display errors to the user.
     */
    public PageReference updatePayments() {
        if (getPaymentsById().isEmpty()) {
            return null;
        }

        try {
            update getPaymentsById().values();
            refreshData();

            // Pass url parameter so the page knows to refresh the data.
            ApexPages.currentPage().getParameters().put('refresh', 'true');

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Success! The payments were updated.'));
            return null;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an issue updating the payments. Error Details: ' + ex.getMessage()));
        }

        return null;
    }

    /**
     * @description Used to delete a payment for a contact/project. Errors and success notifications are displayed to the user.
     */
    public PageReference deletePayment() {
        // If we are unable to find the record for the specified Id somehow, display an error and return early.
        Payment__c paymentToDelete = getPaymentById(TargetPaymentId);

        if (paymentToDelete == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'We were unable to delete the payment. Please try again.'));
            return null;
        }

        try {
            delete paymentToDelete;
            refreshData();

            // Pass url parameter so the page knows to refresh all the data.
            ApexPages.currentPage().getParameters().put('refresh', 'true');

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Success! The payment was deleted.'));
            return null;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an issue deleting the payment. Error Details: ' + ex.getMessage()));
        }

        return null;
    }

    private void refreshData() {
        // Query the contact with the updated rollups.
        List<Contact> contacts = ContactsSelector.selectContactsWithPaymentsById(new Set<Id> { ContactRecord.Id });

        // If for some reason the contact does not exist, return early.
        if (contacts.isEmpty()) {
            return;
        }

        ContactRecord = contacts[0];
    }
}