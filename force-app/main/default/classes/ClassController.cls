public without sharing class ClassController {

    @AuraEnabled(cacheable=true)
    public static List<Dance_Class__c> getActiveClasses() {
        return [
            SELECT Id, Name, Style__c, Instructor__c,
                   Day_of_Week__c, Start_Time__c, Age_Group__c,
                   Fee__c, Duration_Mins__c, Max_Capacity__c,
                   Description__c
            FROM Dance_Class__c
            WHERE IsActive__c = true
            ORDER BY Style__c, Name
            LIMIT 12
        ];
    }

    // NEW separate method: returns a map of classId -> confirmed count
    @AuraEnabled(cacheable=true)
    public static Map<Id, Integer> getConfirmedCounts() {
        Map<Id, Integer> counts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Dance_Class__c cid, COUNT(Id) cnt
            FROM Enrollment__c
            WHERE Status__c = 'Confirmed' AND Dance_Class__c != null
            GROUP BY Dance_Class__c
        ]) {
            counts.put((Id) ar.get('cid'), (Integer) ar.get('cnt'));
        }
        return counts;
    }
}