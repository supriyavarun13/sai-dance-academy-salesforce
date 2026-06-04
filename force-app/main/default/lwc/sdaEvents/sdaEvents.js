import { LightningElement, wire, track } from 'lwc';
import getUpcomingEvents from '@salesforce/apex/EventController.getUpcomingEvents';
import createRsvp from '@salesforce/apex/RsvpController.createRsvp';
import createRsvpCheckoutSession from '@salesforce/apex/StripeCheckoutController.createRsvpCheckoutSession';

const MONTHS = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];

export default class SdaEvents extends LightningElement {
    @track openFormId = null;
    firstName = '';
    lastName = '';
    email = '';
    guests = 1;
    rsvpError = '';
    isProcessing = false;
    showSuccess = false;

    @wire(getUpcomingEvents)
    events;

    get eventList() {
        if (!this.events.data) return [];
        return this.events.data.map((evt) => {
            const d = evt.Event_Date__c ? new Date(evt.Event_Date__c) : null;
            const price = evt.Ticket_Price__c;
            const paid = price && price > 0;
            return {
                ...evt,
                monthLabel: d ? MONTHS[d.getMonth()] : '',
                dayLabel: d ? d.getDate() : '',
                priceLabel: paid ? '$' + price : 'Free',
                showForm: this.openFormId === evt.Id,
                rsvpButtonLabel: paid ? 'RSVP & Pay' : 'Confirm RSVP'
            };
        });
    }

    get noEvents() {
        return this.events.data && this.events.data.length === 0;
    }

    get notProcessing() {
        return !this.isProcessing;
    }

    handleOpenForm(e) {
        const id = e.currentTarget.dataset.id;
        this.openFormId = (this.openFormId === id) ? null : id;
        this.rsvpError = '';
    }

    handleInput(e) {
        const field = e.target.dataset.field;
        this[field] = e.target.value;
    }

    async handleSubmitRsvp(e) {
        this.rsvpError = '';
        const eventId = e.currentTarget.dataset.id;
        const eventName = e.currentTarget.dataset.name;
        const ticketPrice = parseFloat(e.target.dataset.price) || 0;

        if (!this.firstName || !this.lastName || !this.email) {
            this.rsvpError = 'Please fill in your name and email.';
            return;
        }

        this.isProcessing = true;

        try {
            const rsvpResult = await createRsvp({
                firstName: this.firstName,
                lastName: this.lastName,
                email: this.email,
                numberOfGuests: parseInt(this.guests, 10) || 1,
                eventId: eventId,
                ticketPrice: ticketPrice
            });

            if (rsvpResult.errorMessage) {
                this.rsvpError = rsvpResult.errorMessage;
                this.isProcessing = false;
                return;
            }

            if (rsvpResult.isPaid) {
                const origin = window.location.origin;
                const checkoutResult = await createRsvpCheckoutSession({
                    rsvpId: rsvpResult.rsvpId,
                    eventName: eventName,
                    amount: ticketPrice * (parseInt(this.guests, 10) || 1),
                    currency_x: 'usd',
                    successUrl: origin + '/sda/thank-you',
                    cancelUrl: origin + '/sda/events'
                });

                if (checkoutResult.errorMessage) {
                    this.rsvpError = checkoutResult.errorMessage;
                    this.isProcessing = false;
                    return;
                }
                window.location.href = checkoutResult.checkoutUrl;
            } else {
                this.isProcessing = false;
                this.openFormId = null;
                this.showSuccess = true;
                window.scrollTo({ top: 0, behavior: 'smooth' });
            }

        } catch (err) {
            this.rsvpError = 'Something went wrong. Please try again.';
            this.isProcessing = false;
        }
    }
}