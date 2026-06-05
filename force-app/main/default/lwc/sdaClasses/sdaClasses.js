import { LightningElement, api, wire } from 'lwc';
import getActiveClasses from '@salesforce/apex/ClassController.getActiveClasses';

const COLORS = ['c1', 'c2', 'c3', 'c4'];
const RESOURCE_BASE = '/sfsites/c/resource/';

const IMAGE_NAMES = {
    'Bharatanatyam Beginners': 'gallery_bharatanatyam',
    'Bollywood Intermediate':  'gallery_bollywood_teens',
    'Bollywood Kids':          'gallery_bollywood_kids',
    'Contemporary Adults':     'gallery_contemporary',
    'Wednesday Rhythms':       'gallery_rhythm',
    'Folk Dance All Ages':     'home_students',
    'Kathak Advanced':         'gallery_kathak'
};

export default class SdaClasses extends LightningElement {
    @api enableDetails = false;

    @wire(getActiveClasses)
    classes;

    selectedClass;
    showModal = false;

    get classList() {
        if (!this.classes.data) return [];
        return this.classes.data.map((cls, index) => {
            const name = IMAGE_NAMES[cls.Name];
            return {
                ...cls,
                colorClass: 'class-card-img ' + COLORS[index % COLORS.length],
                cardClass: this.enableDetails ? 'class-card clickable' : 'class-card',
                startTimeDisplay: this.formatTime(cls.Start_Time__c),
                imageUrl: name ? RESOURCE_BASE + name : null,
                hasImage: !!name
            };
        });
    }

    formatTime(raw) {
        if (raw === null || raw === undefined) return '';
        let totalMs;
        if (typeof raw === 'number') {
            totalMs = raw;
        } else {
            const match = String(raw).match(/(\d{1,2}):(\d{2})/);
            if (!match) return String(raw);
            return this.toAmPm(parseInt(match[1], 10), parseInt(match[2], 10));
        }
        const totalMinutes = Math.floor(totalMs / 60000);
        return this.toAmPm(Math.floor(totalMinutes / 60), totalMinutes % 60);
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