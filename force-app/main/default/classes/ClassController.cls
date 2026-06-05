public with sharing class ClassController {

    @AuraEnabled(cacheable=true)
    public static List<Dance_Class__c> getActiveClasses() {
        return [
            SELECT Id, Name, Style__c, Instructor__c,
                   Day_of_Week__c, Start_Time__c, Age_Group__c,
                   Fee__c, Duration_Mins__c, Max_Capacity__c, Description__c
            FROM Dance_Class__c
            WHERE IsActive__c = true
            ORDER BY Style__c, Name
            LIMIT 12
        ];
    }
}