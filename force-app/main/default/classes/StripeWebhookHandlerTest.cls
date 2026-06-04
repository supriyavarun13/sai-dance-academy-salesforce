@isTest
private class StripeWebhookHandlerTest {

    // ── Test data setup ───────────────────────────────────────────
    private static Enrollment__c createTestEnrollment() {
        Dance_Class__c testClass = new Dance_Class__c(
            Name          = 'Bollywood Beginners',
            Style__c      = 'Bollywood',
            Instructor__c = 'Test Instructor',
            Fee__c        = 35.00,
            IsActive__c   = true
        );
        insert testClass;

        Contact testContact = new Contact(
            FirstName = 'Priya',
            LastName  = 'Test'
        );
        insert testContact;

        Enrollment__c enrollment = new Enrollment__c(
            Contact__c          = testContact.Id,
            Dance_Class__c      = testClass.Id,
            Status__c           = 'Awaiting Payment',
            GDPR_Consent__c     = true,
            Enrollment_Date__c  = Date.today(),
            Stripe_Session_Id__c = 'cs_test_abc123'
        );
        insert enrollment;

        return enrollment;
    }

    // ── Helper: build a fake REST context ────────────────────────
    // Tests cannot call REST endpoints directly.
    // We simulate the incoming HTTP request manually.
    private static void setRestContext(String body) {
        RestRequest req   = new RestRequest();
        RestResponse res  = new RestResponse();
        req.requestBody   = Blob.valueOf(body);
        req.httpMethod    = 'POST';
        req.requestURI    = '/services/apexrest/stripe/webhook';
        RestContext.request  = req;
        RestContext.response = res;
    }

    // ── Test 1 — Payment success ──────────────────────────────────
    @isTest
    static void testHandleWebhook_PaymentSuccess() {
        Enrollment__c enrollment = createTestEnrollment();

        // Build a fake Stripe payment_intent.succeeded event
        String webhookBody =
            '{"id":"evt_test_001",' +
            '"type":"payment_intent.succeeded",' +
            '"livemode":false,' +
            '"data":{"object":{' +
            '"id":"pi_test_001",' +
            '"status":"succeeded",' +
            '"amount":3500,' +
            '"currency":"gbp",' +
            '"latest_charge":"ch_test_001",' +
            '"metadata":{"enrollment_id":"' + enrollment.Id + '"},' +
            '"last_payment_error":null' +
            '}}}';

        setRestContext(webhookBody);

        Test.startTest();
        StripeWebhookHandler.handleWebhook();
        Test.stopTest();

        // Verify response is 200
        System.assertEquals(200, RestContext.response.statusCode,
            'Should return 200 to Stripe'
        );

        // Verify Enrollment was updated
        Enrollment__c updated = [
            SELECT Status__c, Amount_Paid__c, Stripe_Payment_Intent__c
            FROM Enrollment__c
            WHERE Id = :enrollment.Id
        ];
        System.assertEquals('Confirmed', updated.Status__c,
            'Status should be Confirmed after successful payment'
        );
        System.assertEquals(35.00, updated.Amount_Paid__c,
            'Amount paid should be 35.00'
        );
        System.assertEquals('pi_test_001', updated.Stripe_Payment_Intent__c,
            'Payment Intent ID should be saved'
        );

        // Verify Payment__c record was created
        List<Payment__c> payments = [
            SELECT Status__c, Amount__c, Stripe_Charge_Id__c, Mode__c
            FROM Payment__c
            WHERE Enrollment__c = :enrollment.Id
        ];
        System.assertEquals(1, payments.size(),
            'One Payment record should be created'
        );
        System.assertEquals('Succeeded', payments[0].Status__c,
            'Payment status should be Succeeded'
        );
        System.assertEquals(35.00, payments[0].Amount__c,
            'Payment amount should be 35.00'
        );
        System.assertEquals('ch_test_001', payments[0].Stripe_Charge_Id__c,
            'Charge ID should be saved'
        );
        System.assertEquals('Test', payments[0].Mode__c,
            'Mode should be Test'
        );
    }

    // ── Test 2 — Payment failure ──────────────────────────────────
    @isTest
    static void testHandleWebhook_PaymentFailed() {
        Enrollment__c enrollment = createTestEnrollment();

        String webhookBody =
            '{"id":"evt_test_002",' +
            '"type":"payment_intent.payment_failed",' +
            '"livemode":false,' +
            '"data":{"object":{' +
            '"id":"pi_test_002",' +
            '"status":"payment_failed",' +
            '"amount":3500,' +
            '"currency":"gbp",' +
            '"latest_charge":null,' +
            '"metadata":{"enrollment_id":"' + enrollment.Id + '"},' +
            '"last_payment_error":{"message":"Your card was declined."}' +
            '}}}';

        setRestContext(webhookBody);

        Test.startTest();
        StripeWebhookHandler.handleWebhook();
        Test.stopTest();

        // Verify response is 200
        System.assertEquals(200, RestContext.response.statusCode,
            'Should return 200 even on payment failure'
        );

        // Verify Enrollment status updated to Payment Failed
        Enrollment__c updated = [
            SELECT Status__c
            FROM Enrollment__c
            WHERE Id = :enrollment.Id
        ];
        System.assertEquals('Payment Failed', updated.Status__c,
            'Status should be Payment Failed'
        );

        // Verify Payment__c failure record created with reason
        List<Payment__c> payments = [
            SELECT Status__c, Failure_Reason__c
            FROM Payment__c
            WHERE Enrollment__c = :enrollment.Id
        ];
        System.assertEquals(1, payments.size(),
            'One Payment record should be created for failure'
        );
        System.assertEquals('Failed', payments[0].Status__c,
            'Payment status should be Failed'
        );
        System.assertEquals('Your card was declined.',
            payments[0].Failure_Reason__c,
            'Failure reason should be captured from Stripe'
        );
    }

    // ── Test 3 — Unknown event type ───────────────────────────────
    @isTest
    static void testHandleWebhook_UnknownEventType() {
        String webhookBody =
            '{"id":"evt_test_003",' +
            '"type":"customer.created",' +
            '"livemode":false,' +
            '"data":{"object":{' +
            '"id":"cus_test_001",' +
            '"status":null,' +
            '"amount":0,' +
            '"currency":"gbp",' +
            '"latest_charge":null,' +
            '"metadata":{},' +
            '"last_payment_error":null' +
            '}}}';

        setRestContext(webhookBody);

        Test.startTest();
        StripeWebhookHandler.handleWebhook();
        Test.stopTest();

        // Should still return 200
        System.assertEquals(200, RestContext.response.statusCode,
            'Unknown events should still return 200'
        );
    }

    // ── Test 4 — Empty request body ───────────────────────────────
    @isTest
    static void testHandleWebhook_EmptyBody() {
        setRestContext('');

        Test.startTest();
        StripeWebhookHandler.handleWebhook();
        Test.stopTest();

        // Should return 400 for empty body
        System.assertEquals(400, RestContext.response.statusCode,
            'Empty body should return 400'
        );
    }

    // ── Test 5 — Missing enrollment ID in metadata ─────────────────
    @isTest
    static void testHandleWebhook_MissingEnrollmentId() {
        String webhookBody =
            '{"id":"evt_test_004",' +
            '"type":"payment_intent.succeeded",' +
            '"livemode":false,' +
            '"data":{"object":{' +
            '"id":"pi_test_004",' +
            '"status":"succeeded",' +
            '"amount":3500,' +
            '"currency":"gbp",' +
            '"latest_charge":"ch_test_004",' +
            '"metadata":{},' +
            '"last_payment_error":null' +
            '}}}';

        setRestContext(webhookBody);

        Test.startTest();
        StripeWebhookHandler.handleWebhook();
        Test.stopTest();

        // Should return 200 — missing ID is handled gracefully
        System.assertEquals(200, RestContext.response.statusCode,
            'Missing enrollment ID should be handled gracefully'
        );

        // No Payment records should be created
        List<Payment__c> payments = [SELECT Id FROM Payment__c];
        System.assertEquals(0, payments.size(),
            'No payment records should be created without enrollment ID'
        );
    }
}