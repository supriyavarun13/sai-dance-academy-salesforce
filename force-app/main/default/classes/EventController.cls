public with sharing class EventController {

    @AuraEnabled(cacheable=true)
    public static List<Event__c> getUpcomingEvents() {
        return [
            SELECT Id, Name, Event_Date__c, Event_Time__c, End_Time__c,
                   Venue__c, Description__c, Event_Type__c, Ticket_Price__c,
                   Max_Attendees__c, Current_RSVPs__c, Registration_Deadline__c
            FROM Event__c
            WHERE Is_Active__c = true AND Is_Past__c = false
            ORDER BY Event_Date__c ASC
            LIMIT 12
        ];
    }
}