import { LightningElement, api } from 'lwc';

export default class SdaTestNotice extends LightningElement {
    // On the enroll/events pages, set this true to show the test-card line.
    // On the contact page, leave false.
    @api showCardInfo = false;
}