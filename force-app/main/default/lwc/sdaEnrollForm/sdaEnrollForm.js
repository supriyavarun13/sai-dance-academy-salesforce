import { LightningElement, wire } from 'lwc';
import getActiveClasses from '@salesforce/apex/ClassController.getActiveClasses';
import createEnrollment from '@salesforce/apex/EnrollmentController.createEnrollment';
import createCheckoutSession from '@salesforce/apex/StripeCheckoutController.createCheckoutSession';

export default class SdaEnrollForm extends LightningElement {
    firstName = '';
    lastName = '';
    email = '';
    phone = '';
    selectedClassId = '';
    gdprConsent = false;
    errorMessage = '';
    isProcessing = false;

    classes = [];

    @wire(getActiveClasses)
    wiredClasses({ data, error }) {
        if (data) {
            this.classes = data;
        } else if (error) {
            this.errorMessage = 'Could not load classes.';
        }
    }

    get classOptions() {
        return this.classes.map((c) => ({
            value: c.Id,
            label: c.Name + ' — $' + c.Fee__c
        }));
    }

    get selectedClass() {
        return this.classes.find((c) => c.Id === this.selectedClassId);
    }

    get selectedClassFee() {
        return this.selectedClass ? this.selectedClass.Fee__c : null;
    }

    get showForm() { return !this.isProcessing; }
    get notProcessing() { return !this.isProcessing; }

    handleFirstName(e) { this.firstName = e.target.value; }
    handleLastName(e) { this.lastName = e.target.value; }
    handleEmail(e) { this.email = e.target.value; }
    handlePhone(e) { this.phone = e.target.value; }
    handleClassChange(e) { this.selectedClassId = e.target.value; }
    handleConsent(e) { this.gdprConsent = e.target.checked; }

    async handleEnroll() {
        this.errorMessage = '';

        // Client-side validation
        if (!this.firstName || !this.lastName || !this.email) {
            this.errorMessage = 'Please fill in your name and email.';
            return;
        }
        if (!this.selectedClassId) {
            this.errorMessage = 'Please choose a class.';
            return;
        }
        if (!this.gdprConsent) {
            this.errorMessage = 'Please accept the consent terms.';
            return;
        }

        this.isProcessing = true;

        try {
            // Step 1 — create the enrollment
            const enrollResult = await createEnrollment({
                firstName: this.firstName,
                lastName: this.lastName,
                email: this.email,
                phone: this.phone,
                classId: this.selectedClassId,
                gdprConsent: this.gdprConsent
            });

            if (enrollResult.errorMessage) {
                this.errorMessage = enrollResult.errorMessage;
                this.isProcessing = false;
                return;
            }

            // Step 2 — create Stripe checkout session
            const origin = window.location.origin;
            const checkoutResult = await createCheckoutSession({
                enrollmentId: enrollResult.enrollmentId,
                className: this.selectedClass.Name,
                amount: this.selectedClass.Fee__c,
                currency_x: 'usd',
                successUrl: origin + '/sda/thank-you',
                cancelUrl: origin + '/sda/enroll'
            });

            if (checkoutResult.errorMessage) {
                this.errorMessage = checkoutResult.errorMessage;
                this.isProcessing = false;
                return;
            }

            // Step 3 — redirect to Stripe
            window.location.href = checkoutResult.checkoutUrl;

        } catch (err) {
            this.errorMessage = 'Something went wrong. Please try again.';
            this.isProcessing = false;
        }
    }
}