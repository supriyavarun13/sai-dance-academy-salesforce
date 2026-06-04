public with sharing class GetUpcomingEventsAction {

    public class EventRequest {
        @InvocableVariable public String dummy;
    }

    public class EventResponse {
        @InvocableVariable public String eventInfo;
    }

    @InvocableMethod(label='Get Upcoming Events' description='Returns upcoming active events')
    public static List<EventResponse> getEvents(List<EventRequest> requests) {
        List<Event__c> events = [
            SELECT Name, Event_Date__c, Venue__c, Event_Type__c, Ticket_Price__c
            FROM Event__c
            WHERE Is_Active__c = true AND Is_Past__c = false
            ORDER BY Event_Date__c LIMIT 10
        ];

        String result = '';
        for (Event__c e : events) {
            String price = (e.Ticket_Price__c == null || e.Ticket_Price__c == 0)
                ? 'Free' : '£' + e.Ticket_Price__c;
            result += e.Name + ' — ' + e.Event_Type__c + ' on '
                   + String.valueOf(e.Event_Date__c) + ' at ' + e.Venue__c
                   + ' (' + price + ')\n';
        }
        if (String.isBlank(result)) result = 'No upcoming events at the moment.';

        EventResponse resp = new EventResponse();
        resp.eventInfo = result;
        return new List<EventResponse>{ resp };
    }
}