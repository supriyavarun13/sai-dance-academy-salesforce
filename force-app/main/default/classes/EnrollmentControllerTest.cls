@isTest
private class EnrollmentControllerTest {

    private static Dance_Class__c makeClass() {
        Dance_Class__c c = new Dance_Class__c(
            Name = 'Test Bollywood',
            Style__c = 'Bollywood',
            Instructor__c = 'Test Teacher',
            Fee__c = 40,
            IsActive__c = true
        );
        // NOTE: if your Dance_Class active field is IsActive__c, change above
        insert c;
        return c;
    }

    @isTest
    static void testCreateEnrollment_NewContact() {
        Dance_Class__c c = makeClass();

        Test.startTest();
        EnrollmentController.EnrollResult res = EnrollmentController.createEnrollment(
            'Jane', 'Doe', 'jane.doe@test.com', '07123456789', c.Id, true
        );
        Test.stopTest();

        System.assertNotEquals(null, res.enrollmentId, 'Should return enrollment Id');
        System.assertEquals(null, res.errorMessage, 'No error expected');

        Enrollment__c enr = [SELECT Status__c, Contact__c FROM Enrollment__c WHERE Id = :res.enrollmentId];
        System.assertEquals('Pending Payment', enr.Status__c, 'Status should be Pending Payment');
    }

    @isTest
    static void testCreateEnrollment_ExistingContact() {
        Dance_Class__c c = makeClass();
        Contact existing = new Contact(FirstName='Sam', LastName='Smith', Email='sam@test.com');
        insert existing;

        Test.startTest();
        EnrollmentController.EnrollResult res = EnrollmentController.createEnrollment(
            'Sam', 'Smith', 'sam@test.com', '07000000000', c.Id, true
        );
        Test.stopTest();

        Integer contactCount = [SELECT COUNT() FROM Contact WHERE Email = 'sam@test.com'];
        System.assertEquals(1, contactCount, 'Should reuse existing contact, not create duplicate');
    }

    @isTest
    static void testCreateEnrollment_NoConsent() {
        Dance_Class__c c = makeClass();

        Test.startTest();
        EnrollmentController.EnrollResult res = EnrollmentController.createEnrollment(
            'No', 'Consent', 'no@test.com', '07000000000', c.Id, false
        );
        Test.stopTest();

        System.assertNotEquals(null, res.errorMessage, 'Should error without consent');
        System.assertEquals(null, res.enrollmentId, 'No enrollment should be created');
    }
}