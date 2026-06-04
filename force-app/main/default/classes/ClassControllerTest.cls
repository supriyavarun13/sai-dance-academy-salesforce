@isTest
private class ClassControllerTest {
    @isTest
    static void testGetActiveClasses() {
        Dance_Class__c c = new Dance_Class__c(
            Name = 'Test Bollywood',
            Style__c = 'Bollywood',
            Instructor__c = 'Test Teacher',
            Day_of_Week__c = 'Sunday',
            Fee__c = 40,
            IsActive__c = true
        );
        insert c;

        Test.startTest();
        List<Dance_Class__c> results = ClassController.getActiveClasses();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one active class');
        System.assertEquals('Bollywood', results[0].Style__c, 'Style should match');
    }
}