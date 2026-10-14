import { LightningElement, wire } from 'lwc';

import getMyRequirements
    from '@salesforce/apex/WorkTracker.getMyRequirements';

import startRequirement
    from '@salesforce/apex/WorkTracker.startRequirement';

import completeRequirement
    from '@salesforce/apex/WorkTracker.completeRequirement';

import { refreshApex }
    from '@salesforce/apex';

import USER_ID
    from '@salesforce/user/Id';

import { getRecord }
    from 'lightning/uiRecordApi';

import USER_NAME
    from '@salesforce/schema/User.Name';

import { ShowToastEvent }
    from 'lightning/platformShowToastEvent';


export default class WorkTracker extends LightningElement {

    userId = USER_ID;

    userName = 'Developer';

    requirements = [];

    wiredRequirements;

    isLoading = true;

    errorMessage;


    // Get logged-in user's name
    @wire(getRecord, {
        recordId: '$userId',
        fields: [USER_NAME]
    })
    wiredUser({ data, error }) {

        if (data) {
            this.userName = data.fields.Name.value;
        }

        if (error) {
            console.error('Error loading user:', error);
        }
    }


    // Get assigned requirements
    @wire(getMyRequirements)
    wiredGetRequirements(result) {

        this.wiredRequirements = result;

        const { data, error } = result;

        if (data) {

            this.isLoading = false;

            this.errorMessage = undefined;

            this.requirements = data.map((requirement, index) => {

                return {
                    ...requirement,

                    rowNumber: index + 1,

                    isNotStarted:
                        requirement.Status__c === 'Not Started',

                    isInProgress:
                        requirement.Status__c === 'In Progress',

                    isCompleted:
                        requirement.Status__c === 'Completed',

                    statusClass:
                        this.getStatusClass(
                            requirement.Status__c
                        )
                };
            });
        }

        if (error) {

            this.isLoading = false;

            this.requirements = [];

            this.errorMessage =
                'Unable to load your requirements.';

            console.error(
                'Error loading requirements:',
                error
            );
        }
    }


    // Check if requirements exist
    get hasRequirements() {
        return this.requirements.length > 0;
    }


    // Show no records message
    get showNoRecords() {

        return !this.isLoading &&
               !this.errorMessage &&
               this.requirements.length === 0;
    }


    // Status CSS class
    getStatusClass(status) {

        if (status === 'Completed') {
            return 'status-badge completed-status';
        }

        if (status === 'In Progress') {
            return 'status-badge progress-status';
        }

        return 'status-badge not-started-status';
    }


    // Start Work
    async handleStart(event) {

        const requirementId =
            event.currentTarget.dataset.id;

        this.isLoading = true;

        try {

            await startRequirement({
                requirementId: requirementId
            });

            this.showToast(
                'Success',
                'Work started successfully.',
                'success'
            );

            await refreshApex(
                this.wiredRequirements
            );

        } catch (error) {

            this.isLoading = false;

            console.error(
                'Error starting requirement:',
                error
            );

            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );
        }
    }


    // Complete Work
    async handleComplete(event) {

        const requirementId =
            event.currentTarget.dataset.id;

        this.isLoading = true;

        try {

            await completeRequirement({
                requirementId: requirementId
            });

            this.showToast(
                'Success',
                'Work completed successfully.',
                'success'
            );

            await refreshApex(
                this.wiredRequirements
            );

        } catch (error) {

            this.isLoading = false;

            console.error(
                'Error completing requirement:',
                error
            );

            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );
        }
    }


    // Get error message
    getErrorMessage(error) {

        if (
            error &&
            error.body &&
            error.body.message
        ) {
            return error.body.message;
        }

        return 'Something went wrong. Please try again.';
    }


    // Toast
    showToast(title, message, variant) {

        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}