public with sharing class GetDanceClassesAction {

    public class ClassRequest {
        @InvocableVariable(label='Dance Style' required=false)
        public String style;
    }

    public class ClassResponse {
        @InvocableVariable public String classInfo;
    }

    @InvocableMethod(label='Get Dance Classes' description='Returns active dance classes, optionally filtered by style')
    public static List<ClassResponse> getClasses(List<ClassRequest> requests) {
        ClassRequest req = requests[0];
        String filter = req.style;

        List<Dance_Class__c> classes;
        if (String.isNotBlank(filter)) {
            classes = [
                SELECT Name, Style__c, Instructor__c, Day_of_Week__c,
                       Start_Time__c, Age_Group__c, Fee__c
                FROM Dance_Class__c
                WHERE IsActive__c = true AND Style__c LIKE :('%' + filter + '%')
                ORDER BY Style__c LIMIT 10
            ];
        } else {
            classes = [
                SELECT Name, Style__c, Instructor__c, Day_of_Week__c,
                       Start_Time__c, Age_Group__c, Fee__c
                FROM Dance_Class__c
                WHERE IsActive__c = true
                ORDER BY Style__c LIMIT 10
            ];
        }

        String result = '';
        for (Dance_Class__c c : classes) {
            result += c.Name + ' (' + c.Style__c + ') — '
                   + c.Day_of_Week__c + ' at ' + String.valueOf(c.Start_Time__c)
                   + ', Age: ' + c.Age_Group__c
                   + ', Fee: £' + c.Fee__c + '\n';
        }
        if (String.isBlank(result)) result = 'No matching classes found.';

        ClassResponse resp = new ClassResponse();
        resp.classInfo = result;
        return new List<ClassResponse>{ resp };
    }
}