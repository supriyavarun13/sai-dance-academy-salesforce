@isTest
private class StripeCheckoutControllerTest {

    // ── 1. Mock HTTP callout — simulates Stripe's response ───────
    // Salesforce blocks real HTTP callouts in tests.
    // We create a fake Stripe response to test against.
    private class StripeSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"id":"cs_test_abc123",' +
                '"url":"https://checkout.stripe.com/pay/cs_test_abc123",' +
                '"object":"checkout.session"}'
            );
            return res;
        }
    }

    // ── 2. Mock for Stripe error response ─────────────────────────
    private class StripeErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody(
                '{"error":{"message":"Your card was declined.",' +
                '"type":"card_error","code":"card_declined"}}'
            );
            return res;
        }
    }

    // ── 3. Test data factory ──────────────────────────────────────
    // Creates the minimum records needed for the test
    private static Enrollment__c createTestEnrollment() {
        // Create a Dance Class first (Enrollment lookup requires it)
        Dance_Class__c testClass = new Dance_Class__c(
            Name          = 'Bharatanatyam Beginners',
            Style__c      = 'Bharatanatyam',
            Instructor__c = 'Test Instructor',
            Fee__c        = 40.00,
            IsActive__c   = true
        );
        insert testClass;

        // Create a Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName  = 'Student'
        );
        insert testContact;

        // Create the Enrollment record
        Enrollment__c enrollment = new Enrollment__c(
            Contact__c       = testContact.Id,
            Dance_Class__c   = testClass.Id,
            Status__c        = 'Pending Payment',
            GDPR_Consent__c  = true,
            Enrollment_Date__c = Date.today()
        );
        insert enrollment;

        return enrollment;
    }

    // ── 4. Test 1 — Happy path: Stripe returns success ────────────
    @isTest
    static void testCreateCheckoutSession_Success() {
        Enrollment__c enrollment = createTestEnrollment();

        // Tell Salesforce to use our mock instead of calling real Stripe
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());

        Test.startTest();
        StripeCheckoutController.CheckoutResult result =
            StripeCheckoutController.createCheckoutSession(
                enrollment.Id,
                'Bharatanatyam Beginners',
                40.00,
                'GBP',
                'https://mysite.com/enroll/success',
                'https://mysite.com/enroll/failed'
            );
        Test.stopTest();

        // Verify the result has a URL and no error
        System.assertNotEquals(null, result.checkoutUrl,
            'Checkout URL should not be null on success');
        System.assertEquals(null, result.errorMessage,
            'Error message should be null on success');
        System.assert(
            result.checkoutUrl.contains('checkout.stripe.com'),
            'URL should be a Stripe checkout URL'
        );

        // Verify the Enrollment record was updated
        Enrollment__c updated = [
            SELECT Stripe_Session_Id__c, Status__c
            FROM Enrollment__c
            WHERE Id = :enrollment.Id
        ];
        System.assertEquals('cs_test_abc123',
            updated.Stripe_Session_Id__c,
            'Session ID should be saved to Enrollment'
        );
        System.assertEquals('Awaiting Payment',
            updated.Status__c,
            'Status should be updated to Awaiting Payment'
        );
    }

    // ── 5. Test 2 — Stripe returns an error ───────────────────────
    @isTest
    static void testCreateCheckoutSession_StripeError() {
        Enrollment__c enrollment = createTestEnrollment();

        Test.setMock(HttpCalloutMock.class, new StripeErrorMock());

        Test.startTest();
        StripeCheckoutController.CheckoutResult result =
            StripeCheckoutController.createCheckoutSession(
                enrollment.Id,
                'Bharatanatyam Beginners',
                40.00,
                'GBP',
                'https://mysite.com/enroll/success',
                'https://mysite.com/enroll/failed'
            );
        Test.stopTest();

        // Verify error is captured correctly
        System.assertNotEquals(null, result.errorMessage,
            'Error message should be populated on failure'
        );
        System.assertEquals(null, result.checkoutUrl,
            'Checkout URL should be null on failure'
        );
    }

    // ── 6. Test 3 — Invalid enrollment ID ─────────────────────────
    @isTest
    static void testCreateCheckoutSession_InvalidId() {
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());

        Test.startTest();
        StripeCheckoutController.CheckoutResult result =
            StripeCheckoutController.createCheckoutSession(
                'invalid_id_000000000000',
                'Test Class',
                40.00,
                'GBP',
                'https://mysite.com/enroll/success',
                'https://mysite.com/enroll/failed'
            );
        Test.stopTest();

        // Exception should be caught and returned as error message
        System.assertNotEquals(null, result.errorMessage,
            'Should return error message for invalid ID'
        );
    }
}