@RestResource(urlMapping='/stripe/webhook/*')
global without sharing class StripeWebhookHandler {

    @HttpPost
    global static void handleWebhook() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String requestBody = req.requestBody != null
                ? req.requestBody.toString() : '';

            if (String.isBlank(requestBody)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Empty request body');
                return;
            }

            // Untyped parse — immune to reserved words & extra fields
            Map<String, Object> event =
                (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            String eventType = (String) event.get('type');

            Map<String, Object> dataMap =
                (Map<String, Object>) event.get('data');
            Map<String, Object> obj =
                (Map<String, Object>) dataMap.get('object');

            if (eventType == 'payment_intent.succeeded') {
                handlePaymentSuccess(obj);
            } else if (eventType == 'payment_intent.payment_failed') {
                handlePaymentFailure(obj);
            } else {
                res.statusCode = 200;
                res.responseBody = Blob.valueOf('Event type not handled');
                return;
            }

            res.statusCode = 200;
            res.responseBody = Blob.valueOf('OK');

        } catch (Exception e) {
            // Surface the REAL error (still 200 so Stripe doesn't retry-storm)
            System.debug(LoggingLevel.ERROR,
                'Webhook error: ' + e.getMessage() + ' | line: ' + e.getLineNumber());
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(
                'Internal error: ' + e.getMessage());
        }
    }

    private static void handlePaymentSuccess(Map<String, Object> obj) {
        String paymentIntentId = (String) obj.get('id');
        String latestCharge    = (String) obj.get('latest_charge');
        Object amountObj        = obj.get('amount');
        Decimal amount = (amountObj != null)
            ? ((Decimal) amountObj) / 100.0 : 0;
        String currencyCode = obj.get('currency') != null
            ? ((String) obj.get('currency')).toUpperCase() : 'GBP';

        Map<String, Object> metadata =
            (Map<String, Object>) obj.get('metadata');
        String enrollmentId = (metadata != null)
            ? (String) metadata.get('enrollment_id') : null;

        if (String.isBlank(enrollmentId)) {
            System.debug(LoggingLevel.ERROR, 'No enrollment_id in metadata');
            return;
        }

        List<Enrollment__c> enrollments = [
            SELECT Id, Status__c FROM Enrollment__c
            WHERE Id = :enrollmentId LIMIT 1
        ];
        if (enrollments.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'Enrollment not found: ' + enrollmentId);
            return;
        }

        Enrollment__c enrollment = enrollments[0];
        enrollment.Status__c                = 'Confirmed';
        enrollment.Stripe_Payment_Intent__c = paymentIntentId;
        enrollment.Amount_Paid__c           = amount;
        update enrollment;

        insert new Payment__c(
            Enrollment__c        = enrollment.Id,
            Stripe_Payment_Id__c = paymentIntentId,
            Stripe_Charge_Id__c  = latestCharge,
            Amount__c            = amount,
            Currency_Code__c     = currencyCode,
            Status__c            = 'Succeeded',
            Mode__c              = 'Test',
            Payment_Date__c      = DateTime.now()
        );
    }

    private static void handlePaymentFailure(Map<String, Object> obj) {
        String paymentIntentId = (String) obj.get('id');
        Object amountObj        = obj.get('amount');
        Decimal amount = (amountObj != null)
            ? ((Decimal) amountObj) / 100.0 : 0;
        String currencyCode = obj.get('currency') != null
            ? ((String) obj.get('currency')).toUpperCase() : 'GBP';

        Map<String, Object> metadata =
            (Map<String, Object>) obj.get('metadata');
        String enrollmentId = (metadata != null)
            ? (String) metadata.get('enrollment_id') : null;
        if (String.isBlank(enrollmentId)) return;

        List<Enrollment__c> enrollments = [
            SELECT Id, Status__c FROM Enrollment__c
            WHERE Id = :enrollmentId LIMIT 1
        ];
        if (enrollments.isEmpty()) return;

        Enrollment__c enrollment = enrollments[0];
        enrollment.Status__c = 'Payment Failed';
        update enrollment;

        Map<String, Object> lastErr =
            (Map<String, Object>) obj.get('last_payment_error');
        String failureReason = (lastErr != null && lastErr.get('message') != null)
            ? (String) lastErr.get('message') : 'Payment failed';

        insert new Payment__c(
            Enrollment__c        = enrollment.Id,
            Stripe_Payment_Id__c = paymentIntentId,
            Amount__c            = amount,
            Currency_Code__c     = currencyCode,
            Status__c            = 'Failed',
            Mode__c              = 'Test',
            Payment_Date__c      = DateTime.now(),
            Failure_Reason__c    = failureReason
        );
    }
}