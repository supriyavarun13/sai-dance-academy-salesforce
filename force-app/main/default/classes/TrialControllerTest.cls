@isTest
private class TrialControllerTest {

    @isTest
    static void testCreateTrialLead_success() {
        Test.startTest();
        TrialController.TrialResult result = TrialController.createTrialLead(
            'Asha', 'Rao', 'asha.rao@example.com', '5551234567',
            'Bharatanatyam Beginners', 'Weekday evenings'
        );
        Test.stopTest();

        System.assertNotEquals(null, result.leadId, 'Lead should be created');
        System.assertEquals(null, result.errorMessage, 'No error expected');

        Lead ld = [
            SELECT FirstName, LastName, Email, Phone, LeadSource, Description
            FROM Lead WHERE Id = :result.leadId
        ];
        System.assertEquals('Asha', ld.FirstName);
        System.assertEquals('Rao', ld.LastName);
        System.assertEquals('asha.rao@example.com', ld.Email);
        System.assertEquals('Trial Request', ld.LeadSource, 'Lead source should mark it as a trial');
        System.assert(
            ld.Description != null && ld.Description.contains('Bharatanatyam Beginners'),
            'Description should capture the class interest'
        );
    }

    @isTest
    static void testCreateTrialLead_missingEmail() {
        Test.startTest();
        TrialController.TrialResult result = TrialController.createTrialLead(
            'NoEmail', 'User', '', '', 'Kathak Advanced', ''
        );
        Test.stopTest();

        System.assertEquals(null, result.leadId, 'No lead should be created without email');
        System.assertNotEquals(null, result.errorMessage, 'An error message is expected');
    }

    @isTest
    static void testCreateTrialLead_minimalFields() {
        // Only required-ish fields; optional ones blank
        Test.startTest();
        TrialController.TrialResult result = TrialController.createTrialLead(
            '', 'Solo', 'solo@example.com', '', '', ''
        );
        Test.stopTest();

        System.assertNotEquals(null, result.leadId, 'Lead should be created with just last name + email');
        Lead ld = [SELECT LeadSource FROM Lead WHERE Id = :result.leadId];
        System.assertEquals('Trial Request', ld.LeadSource);
    }
}