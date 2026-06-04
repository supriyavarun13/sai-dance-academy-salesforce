public without sharing class EnrollmentController {

    // Wrapper returned to the LWC
    public class EnrollResult {
        @AuraEnabled public String enrollmentId;
        @AuraEnabled public String errorMessage;
    }

    @AuraEnabled
    public static EnrollResult createEnrollment(
        String firstName,
        String lastName,
        String email,
        String phone,
        String classId,
        Boolean gdprConsent
    ) {
        EnrollResult result = new EnrollResult();

        try {
            // 1. Validate GDPR consent
            if (gdprConsent != true) {
                result.errorMessage = 'You must accept the consent terms to enroll.';
                return result;
            }

            // 2. Find existing Contact by email, or create new
            Contact con;
            List<Contact> existing = [
                SELECT Id FROM Contact WHERE Email = :email LIMIT 1
            ];
            if (!existing.isEmpty()) {
                con = existing[0];
            } else {
                con = new Contact(
                    FirstName = firstName,
                    LastName  = lastName,
                    Email     = email,
                    Phone     = phone
                );
                insert con;
            }

            // 3. Create the Enrollment record
            Enrollment__c enr = new Enrollment__c(
                Contact__c         = con.Id,
                Dance_Class__c     = classId,
                Status__c          = 'Pending Payment',
                GDPR_Consent__c    = gdprConsent,
                Enrollment_Date__c = Date.today()
            );
            insert enr;

            result.enrollmentId = enr.Id;

        } catch (Exception e) {
            result.errorMessage = 'Could not create enrollment: ' + e.getMessage();
        }

        return result;
    }
}