import { LightningElement, api, wire } from 'lwc';
import getActiveClasses from '@salesforce/apex/ClassController.getActiveClasses';
import getConfirmedCounts from '@salesforce/apex/ClassController.getConfirmedCounts';

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

    @wire(getActiveClasses) classes;
    @wire(getConfirmedCounts) counts;

    selectedClass;
    showModal = false;

    get classList() {
        if (!this.classes.data) return [];
        const countMap = (this.counts && this.counts.data) ? this.counts.data : {};
        return this.classes.data.map((cls, index) => {
            const name = IMAGE_NAMES[cls.Name];
            const cap = cls.Max_Capacity__c || 0;
            const confirmed = countMap[cls.Id] || 0;
            const left = cap - confirmed;
            const spotsLeft = left < 0 ? 0 : left;
            const isFull = cap > 0 && confirmed >= cap;
            return {
                ...cls,
                colorClass: 'class-card-img ' + COLORS[index % COLORS.length],
                cardClass: this.enableDetails ? 'class-card clickable' : 'class-card',
                startTimeDisplay: this.formatTime(cls.Start_Time__c),
                imageUrl: name ? RESOURCE_BASE + name : null,
                hasImage: !!name,
                spotsLeft: spotsLeft,
                isFull: isFull,
                spotsLabel: isFull ? 'Class Full' : spotsLeft + ' spots left'
            };
        });
    }

    formatTime(raw) {
        if (raw === null || raw === undefined) return '';
        let totalMs;
        if (typeof raw === 'number') { totalMs = raw; }
        else {
            const m = String(raw).match(/(\d{1,2}):(\d{2})/);
            if (!m) return String(raw);
            return this.toAmPm(parseInt(m[1],10), parseInt(m[2],10));
        }
        const tm = Math.floor(totalMs/60000);
        return this.toAmPm(Math.floor(tm/60), tm%60);
    }
    toAmPm(h,m){const p=h>=12?'PM':'AM';let h12=h%12;if(h12===0)h12=12;const mm=m<10?'0'+m:''+m;return `${h12}:${mm} ${p}`;}

    handleCardClick(event) {
        if (!this.enableDetails) return;
        const id = event.currentTarget.dataset.id;
        const found = this.classList.find(c => c.Id === id);
        if (found) { this.selectedClass = found; this.showModal = true; }
    }
    closeModal(){ this.showModal=false; this.selectedClass=undefined; }
    stopProp(e){ e.stopPropagation(); }
}