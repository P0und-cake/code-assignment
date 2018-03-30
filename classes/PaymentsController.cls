/**
 * @description Controller for the payments page.
 */
public with sharing class PaymentsController {

    private List<Contact> contactsWithPayments;

    /**
     * @description This method gets all contacts that have at least 1 payment. The 'refresh' url parameter is used by a
     *              component to tell the page if all the data should be refreshed. The parameter is sent after the
     *              components complete DML operations.
     */
    public List<Contact> getContacts() {
        if (contactsWithPayments != null && ApexPages.currentPage().getParameters().get('refresh') != 'true') {
            return contactsWithPayments;
        }

        contactsWithPayments = ContactsSelector.selectContactsWithPayments();

        return contactsWithPayments;
    }

    public Boolean getHasContacts() {
        return !getContacts().isEmpty();
    }
}