@isTest
private class EventControllerTest {
    @isTest
    static void testGetUpcomingEvents() {
        Event__c e = new Event__c(
            Name = 'Test Recital',
            Event_Date__c = Date.today().addDays(30),
            Event_Time__c = Time.newInstance(18, 0, 0, 0),
            Venue__c = 'Test Hall',
            Event_Type__c = 'Recital',
            Ticket_Price__c = 0,
            Is_Active__c = true
        );
        insert e;

        Test.startTest();
        List<Event__c> results = EventController.getUpcomingEvents();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one upcoming event');
    }
}