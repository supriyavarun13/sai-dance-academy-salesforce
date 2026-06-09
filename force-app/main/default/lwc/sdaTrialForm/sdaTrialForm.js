import { LightningElement, wire, track } from 'lwc';
import getActiveClasses from '@salesforce/apex/ClassController.getActiveClasses';
import createTrialLead from '@salesforce/apex/TrialController.createTrialLead';

export default class SdaTrialForm extends LightningElement {
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track phone = '';
    @track classInterest = '';
    @track preferredTiming = '';

    submitted = false;
    errorMessage = '';
    isSubmitting = false;

    classOptions = [];

    @wire(getActiveClasses)
    wiredClasses({ data }) {
        if (data) {
            // getActiveClasses returns List<Dance_Class__c>
            this.classOptions = data.map((c) => ({
                label: c.Name + ' (' + c.Style__c + ')',
                value: c.Name
            }));
        }
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    async handleSubmit() {
        this.errorMessage = '';
        if (!this.email || !this.lastName) {
            this.errorMessage = 'Please provide at least your name and email.';
            return;
        }
        this.isSubmitting = true;
        try {
            const result = await createTrialLead({
                firstName: this.firstName,
                lastName: this.lastName,
                email: this.email,
                phone: this.phone,
                classInterest: this.classInterest,
                preferredTiming: this.preferredTiming
            });
            if (result.errorMessage) {
                this.errorMessage = result.errorMessage;
            } else {
                this.submitted = true;
            }
        } catch (e) {
            this.errorMessage = 'Something went wrong. Please try again.';
        } finally {
            this.isSubmitting = false;
        }
    }
}