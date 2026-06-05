@isTest
private class RsvpControllerTest {

    private static Event__c makeEvent(Decimal price) {
        Event__c e = new Event__c(
            Name = 'Test Event',
            Event_Date__c = Date.today().addDays(20),
            Event_Time__c = Time.newInstance(18, 0, 0, 0),
            Venue__c = 'Test Venue',
            Event_Type__c = 'Workshop',
            Ticket_Price__c = price,
            Is_Active__c = true
        );
        insert e;
        return e;
    }

    @isTest
    static void testFreeRsvp() {
        Event__c e = makeEvent(0);

        Test.startTest();
        RsvpController.RsvpResult res = RsvpController.createRsvp(
            'Free', 'Guest', 'free@test.com', 2, e.Id, 0
        );
        Test.stopTest();

        System.assertNotEquals(null, res.rsvpId, 'RSVP should be created');
        System.assertEquals(false, res.isPaid, 'Should be free');
        RSVP__c r = [SELECT Status__c FROM RSVP__c WHERE Id = :res.rsvpId];
        System.assertEquals('Confirmed', r.Status__c, 'Free RSVP should be Confirmed');
    }

    @isTest
    static void testPaidRsvp() {
        Event__c e = makeEvent(25);

        Test.startTest();
        RsvpController.RsvpResult res = RsvpController.createRsvp(
            'Paid', 'Guest', 'paid@test.com', 1, e.Id, 25
        );
        Test.stopTest();

        System.assertEquals(true, res.isPaid, 'Should be paid');
        System.assertNotEquals(null, res.rsvpId, 'RSVP should be created');
        RSVP__c r = [SELECT Status__c FROM RSVP__c WHERE Id = :res.rsvpId];
        System.assertEquals('Pending Payment', r.Status__c, 'Paid RSVP should be Pending Payment');
    }
}