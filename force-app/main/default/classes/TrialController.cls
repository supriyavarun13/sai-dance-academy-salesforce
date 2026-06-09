public without sharing class TrialController {

    public class TrialResult {
        @AuraEnabled public String leadId;
        @AuraEnabled public String errorMessage;
    }

    @AuraEnabled
    public static TrialResult createTrialLead(
        String firstName,
        String lastName,
        String email,
        String phone,
        String classInterest,
        String preferredTiming
    ) {
        TrialResult result = new TrialResult();
        try {
            // Basic validation
            if (String.isBlank(email) || String.isBlank(lastName)) {
                result.errorMessage = 'Please provide at least your name and email.';
                return result;
            }

            Lead ld = new Lead(
                FirstName   = firstName,
                LastName    = String.isBlank(lastName) ? 'Trial Enquiry' : lastName,
                Email       = email,
                Phone       = phone,
                Company     = 'Trial Request',          // Lead requires Company; used as a marker
                LeadSource  = 'Trial Request',
                Description = 'Trial class request.'
                    + (String.isNotBlank(classInterest) ? ' Interested in: ' + classInterest + '.' : '')
                    + (String.isNotBlank(preferredTiming) ? ' Preferred timing: ' + preferredTiming + '.' : '')
            );
            insert ld;
            result.leadId = ld.Id;

        } catch (Exception e) {
            result.errorMessage = 'Could not submit your trial request: ' + e.getMessage();
        }
        return result;
    }
}