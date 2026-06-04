@isTest
private class AgentActionsTest {
    @isTest
    static void testGetClasses() {
        insert new Dance_Class__c(Name='Test', Style__c='Bollywood', Fee__c=40, IsActive__c=true);

        Test.startTest();
        GetDanceClassesAction.ClassRequest req = new GetDanceClassesAction.ClassRequest();
        List<GetDanceClassesAction.ClassResponse> res =
            GetDanceClassesAction.getClasses(new List<GetDanceClassesAction.ClassRequest>{ req });
        Test.stopTest();

        System.assert(res[0].classInfo != null, 'Should return class info');
    }

    @isTest
    static void testGetEvents() {
        insert new Event__c(Name='Test Event', Event_Date__c=Date.today().addDays(10),
            Venue__c='Hall', Event_Type__c='Workshop', Ticket_Price__c=0, Is_Active__c=true);

        Test.startTest();
        GetUpcomingEventsAction.EventRequest req = new GetUpcomingEventsAction.EventRequest();
        List<GetUpcomingEventsAction.EventResponse> res =
            GetUpcomingEventsAction.getEvents(new List<GetUpcomingEventsAction.EventRequest>{ req });
        Test.stopTest();

        System.assert(res[0].eventInfo != null, 'Should rsf project deploy start -d force-app/main/default/classes/GetDanceClassesAction.clseturn event info');
    }
}