import { LightningElement, api, wire } from 'lwc';
import getActiveClasses from '@salesforce/apex/ClassController.getActiveClasses';

const COLORS = ['c1', 'c2', 'c3', 'c4'];

export default class SdaClasses extends LightningElement {
    @api enableDetails = false;

    @wire(getActiveClasses)
    classes;

    selectedClass;
    showModal = false;

    get classList() {
        if (!this.classes.data) return [];
        return this.classes.data.map((cls, index) => ({
            ...cls,
            colorClass: 'class-card-img ' + COLORS[index % COLORS.length],
            cardClass: this.enableDetails ? 'class-card clickable' : 'class-card',
            startTimeDisplay: this.formatTime(cls.Start_Time__c)
        }));
    }

    // Salesforce Time fields arrive as milliseconds-since-midnight (a number)
    // or sometimes a string like "10:00:00.000Z". Handle both.
    formatTime(raw) {
        if (raw === null || raw === undefined) return '';

        let totalMs;
        if (typeof raw === 'number') {
            totalMs = raw;
        } else {
            // string form e.g. "10:00:00.000Z" -> parse HH and MM
            const match = String(raw).match(/(\d{1,2}):(\d{2})/);
            if (!match) return String(raw);
            const h = parseInt(match[1], 10);
            const m = parseInt(match[2], 10);
            return this.toAmPm(h, m);
        }

        const totalMinutes = Math.floor(totalMs / 60000);
        const h = Math.floor(totalMinutes / 60);
        const m = totalMinutes % 60;
        return this.toAmPm(h, m);
    }

    toAmPm(h, m) {
        const period = h >= 12 ? 'PM' : 'AM';
        let hour12 = h % 12;
        if (hour12 === 0) hour12 = 12;
        const mm = m < 10 ? '0' + m : '' + m;
        return `${hour12}:${mm} ${period}`;
    }

    handleCardClick(event) {
        if (!this.enableDetails) return;
        const classId = event.currentTarget.dataset.id;
        const found = this.classList.find((c) => c.Id === classId);
        if (found) {
            this.selectedClass = found;
            this.showModal = true;
        }
    }

    closeModal() {
        this.showModal = false;
        this.selectedClass = undefined;
    }

    stopProp(event) {
        event.stopPropagation();
    }
}