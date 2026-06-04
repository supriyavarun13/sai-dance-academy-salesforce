public without sharing class RsvpController {

    public class RsvpResult {
        @AuraEnabled public String rsvpId;
        @AuraEnabled public Boolean isPaid;
        @AuraEnabled public String errorMessage;
    }

    // Step 1 — create RSVP only (DML, no callout)
    @AuraEnabled
    public static RsvpResult createRsvp(
        String firstName,
        String lastName,
        String email,
        Integer numberOfGuests,
        String eventId,
        Decimal ticketPrice
    ) {
        RsvpResult result = new RsvpResult();

        try {
            Contact con;
            List<Contact> existing = [SELECT Id FROM Contact WHERE Email = :email LIMIT 1];
            if (!existing.isEmpty()) {
                con = existing[0];
            } else {
                con = new Contact(FirstName = firstName, LastName = lastName, Email = email);
                insert con;
            }

            Boolean paid = (ticketPrice != null && ticketPrice > 0);
            result.isPaid = paid;

            RSVP__c rsvp = new RSVP__c(
                Contact__c          = con.Id,
                Event__c            = eventId,
                Number_of_Guests__c = numberOfGuests,
                RSVP_Date__c        = Date.today(),
                Status__c           = paid ? 'Pending Payment' : 'Confirmed'
            );
            insert rsvp;
            result.rsvpId = rsvp.Id;

        } catch (Exception e) {
            result.errorMessage = 'Could not create RSVP: ' + e.getMessage();
        }

        return result;
    }
}   