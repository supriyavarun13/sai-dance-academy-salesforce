public without sharing class StripeCheckoutController {
    // ── 1. Public wrapper class ───────────────────────────────────
    // This is what the LWC receives back from this method.
    // We wrap the URL and any error in one neat object.
    public class CheckoutResult {
        @AuraEnabled public String checkoutUrl;
        @AuraEnabled public String errorMessage;
    }

    // ── 2. The main method called by the LWC ─────────────────────
    // @AuraEnabled        = makes it callable from Lightning components
    // cacheable=false     = never cache — every enrollment is unique
    @AuraEnabled(cacheable=false)
    public static CheckoutResult createCheckoutSession(
        String enrollmentId,
        String className,
        Decimal amount,
        String currency_x,
        String successUrl,
        String cancelUrl
    ) {
        CheckoutResult result = new CheckoutResult();

        try {
            // ── 3. Build the request body ─────────────────────────
            // Stripe expects form-encoded data (not JSON) for this endpoint.
            // amount must be in the smallest currency unit:
            // £10.00 = 1000 pence | $10.00 = 1000 cents
            Long amountInPence = (Long)(amount * 100);

            String body =
                'mode=payment' +
                '&success_url=' + EncodingUtil.urlEncode(successUrl, 'UTF-8') +
                '&cancel_url='  + EncodingUtil.urlEncode(cancelUrl,  'UTF-8') +
                '&line_items[0][price_data][currency]='
                    + EncodingUtil.urlEncode(currency_x, 'UTF-8') +
                '&line_items[0][price_data][unit_amount]=' + amountInPence +
                '&line_items[0][price_data][product_data][name]='
                    + EncodingUtil.urlEncode(className, 'UTF-8') +
                '&line_items[0][quantity]=1' +
                '&metadata[enrollment_id]='
                    + EncodingUtil.urlEncode(enrollmentId, 'UTF-8') +
                '&payment_intent_data[metadata][enrollment_id]='
                    + EncodingUtil.urlEncode(enrollmentId, 'UTF-8');

            // ── 4. Make the HTTP callout ──────────────────────────
            // callout:Stripe_API = our Named Credential name
            // /v1/checkout/sessions = Stripe's endpoint
            // Salesforce automatically adds the Authorization header
            // from the Named Credential — we never touch the secret key
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Stripe_API/v1/checkout/sessions');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody(body);
            req.setTimeout(20000); // 20 second timeout

            Http http = new Http();
            HttpResponse res = http.send(req);

            // ── 5. Handle the response ────────────────────────────
            if (res.getStatusCode() == 200) {
                // Parse the JSON Stripe returns
                Map<String, Object> responseMap =
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                String sessionId  = (String) responseMap.get('id');
                String sessionUrl = (String) responseMap.get('url');

                // ── 6. Save the Stripe Session ID to the Enrollment record ──
                // Critical — the webhook handler uses this ID to find
                // the right Enrollment when Stripe calls back
                Enrollment__c enrollment = new Enrollment__c(
                    Id       = enrollmentId,
                    Stripe_Session_Id__c = sessionId,
                    Status__c            = 'Awaiting Payment'
                );
                update enrollment;

                result.checkoutUrl = sessionUrl;

            } else {
                // Stripe returned an error — parse the message
                Map<String, Object> errorMap =
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> errorDetail =
                    (Map<String, Object>) errorMap.get('error');
                result.errorMessage = (String) errorDetail.get('message');
            }

        } catch (Exception e) {
            result.errorMessage = 'Unexpected error: ' + e.getMessage();
        }

        return result;
    }

    // ── RSVP version — updates RSVP__c instead of Enrollment__c ──
    @AuraEnabled(cacheable=false)
    public static CheckoutResult createRsvpCheckoutSession(
        String rsvpId,
        String eventName,
        Decimal amount,
        String currency_x,
        String successUrl,
        String cancelUrl
    ) {
        CheckoutResult result = new CheckoutResult();

        try {
            Long amountInPence = (Long)(amount * 100);

            String body =
                'mode=payment' +
                '&success_url=' + EncodingUtil.urlEncode(successUrl, 'UTF-8') +
                '&cancel_url='  + EncodingUtil.urlEncode(cancelUrl,  'UTF-8') +
                '&line_items[0][price_data][currency]='
                    + EncodingUtil.urlEncode(currency_x, 'UTF-8') +
                '&line_items[0][price_data][unit_amount]=' + amountInPence +
                '&line_items[0][price_data][product_data][name]='
                    + EncodingUtil.urlEncode(eventName, 'UTF-8') +
                '&line_items[0][quantity]=1' +
                '&metadata[rsvp_id]='
                    + EncodingUtil.urlEncode(rsvpId, 'UTF-8') +
                '&payment_intent_data[metadata][rsvp_id]='
                    + EncodingUtil.urlEncode(rsvpId, 'UTF-8');

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Stripe_API/v1/checkout/sessions');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody(body);
            req.setTimeout(20000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap =
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String sessionId  = (String) responseMap.get('id');
                String sessionUrl = (String) responseMap.get('url');

                RSVP__c rsvp = new RSVP__c(
                    Id = rsvpId,
                    Status__c = 'Pending Payment'
                );
                update rsvp;

                result.checkoutUrl = sessionUrl;
            } else {
                Map<String, Object> errorMap =
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> errorDetail =
                    (Map<String, Object>) errorMap.get('error');
                result.errorMessage = (String) errorDetail.get('message');
            }
        } catch (Exception e) {
            result.errorMessage = 'Unexpected error: ' + e.getMessage();
        }

        return result;
    }
}