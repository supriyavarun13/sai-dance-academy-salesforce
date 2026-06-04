import { LightningElement, wire } from 'lwc';
import getActiveClasses from '@salesforce/apex/ClassController.getActiveClasses';

const COLORS = ['c1', 'c2', 'c3', 'c4'];

export default class SdaClasses extends LightningElement {
    @wire(getActiveClasses)
    classes;

    get classList() {
        if (!this.classes.data) return [];
        return this.classes.data.map((cls, index) => ({
            ...cls,
            colorClass: 'class-card-img ' + COLORS[index % COLORS.length]
        }));
    }
}