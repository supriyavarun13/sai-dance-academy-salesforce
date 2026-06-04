@isTest
private class RsvpControllerTest {

    private static Event__c makeEvent(Decimal price) {
        Event__c e = new Event__c(
            Name = 'Test Event',
            Event_Date__c = Date.today().addDays(20),
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
            'Free', 'Guest', 'free@test.com', 2, e.Id, e.Name, 0,
            'https://x.com/success', 'https://x.com/cancel'
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
        Test.setMock(HttpCalloutMock.class, new StripeMock());

        Test.startTest();
        RsvpController.RsvpResult res = RsvpController.createRsvp(
            'Paid', 'Guest', 'paid@test.com', 1, e.Id, e.Name, 25,
            'https://x.com/success', 'https://x.com/cancel'
        );
        Test.stopTest();

        System.assertEquals(true, res.isPaid, 'Should be paid');
        System.assertNotEquals(null, res.rsvpId, 'RSVP should be created');
    }

    // Mock for the Stripe callout
    private class StripeMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"id":"cs_test_123","url":"https://checkout.stripe.com/test"}');
            return res;
        }
    }
}