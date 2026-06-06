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
            ? ((String) obj.get('currency')).toUpperCase() : 'USD';

        Map<String, Object> metadata =
            (Map<String, Object>) obj.get('metadata');
        if (metadata == null) {
            System.debug(LoggingLevel.ERROR, 'No metadata in payment');
            return;
        }

        String enrollmentId = (String) metadata.get('enrollment_id');
        String rsvpId        = (String) metadata.get('rsvp_id');

        if (String.isNotBlank(enrollmentId)) {
            // ---- CLASS ENROLLMENT ----
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

        } else if (String.isNotBlank(rsvpId)) {
            // ---- EVENT RSVP ----
            // MVP: confirm the RSVP. No Payment__c (master-detail requires Enrollment).
            // Future (Option 3): add optional RSVP__c lookup to Payment__c for audit.
            List<RSVP__c> rsvps = [
                SELECT Id, Status__c FROM RSVP__c
                WHERE Id = :rsvpId LIMIT 1
            ];
            if (rsvps.isEmpty()) {
                System.debug(LoggingLevel.ERROR, 'RSVP not found: ' + rsvpId);
                return;
            }
            RSVP__c rsvp = rsvps[0];
            rsvp.Status__c = 'Confirmed';
            update rsvp;

        } else {
            System.debug(LoggingLevel.ERROR, 'No enrollment_id or rsvp_id in metadata');
            return;
        }
    }

    private static void handlePaymentFailure(Map<String, Object> obj) {
        String paymentIntentId = (String) obj.get('id');
        Object amountObj        = obj.get('amount');
        Decimal amount = (amountObj != null)
            ? ((Decimal) amountObj) / 100.0 : 0;
        String currencyCode = obj.get('currency') != null
            ? ((String) obj.get('currency')).toUpperCase() : 'USD';

        Map<String, Object> metadata =
            (Map<String, Object>) obj.get('metadata');
        if (metadata == null) return;

        String enrollmentId = (String) metadata.get('enrollment_id');
        String rsvpId        = (String) metadata.get('rsvp_id');

        if (String.isNotBlank(enrollmentId)) {
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

        } else if (String.isNotBlank(rsvpId)) {
            List<RSVP__c> rsvps = [
                SELECT Id, Status__c FROM RSVP__c
                WHERE Id = :rsvpId LIMIT 1
            ];
            if (rsvps.isEmpty()) return;
            RSVP__c rsvp = rsvps[0];
            rsvp.Status__c = 'Payment Failed';
            update rsvp;
        }
    }
}