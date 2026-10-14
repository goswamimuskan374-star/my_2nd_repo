import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getBulkActionData from '@salesforce/apex/BulkActionController.getBulkActionData';
import bulkLink from '@salesforce/apex/BulkActionController.bulkLink';
import bulkUnlink from '@salesforce/apex/BulkActionController.bulkUnlink';
import bulkDelete from '@salesforce/apex/BulkActionController.bulkDelete';

export default class BulkActionManager extends LightningElement {
    @api objectApiName;

    _recordId;

    @track unlinkedRecords = [];
    @track linkedRecords = [];
    @track deleteRecords = [];

    title = 'Link Unlink Delete';
    ObjectApiName;
    FieldApiName;
    isLoading = false;

    selectedUnlinkedIds = [];
    selectedLinkedIds = [];
    selectedDeleteIds = [];

    columns = [
        {
            label: 'Record',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'displayValue' },
                target: '_blank'
            }
        },
        {
            label: 'Record Id',
            fieldName: 'Id',
            type: 'text'
        }
    ];

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;

        if (value) {
            this.loadData();
        }
    }

    get disableLink() {
        return this.selectedUnlinkedIds.length === 0 || this.isLoading;
    }

    get disableUnlink() {
        return this.selectedLinkedIds.length === 0 || this.isLoading;
    }

    get disableDelete() {
        return this.selectedDeleteIds.length === 0 || this.isLoading;
    }

    async loadData() {
        this.isLoading = true;

        try {
            const response = await getBulkActionData({
                parentRecordId: this.recordId
            });

            this.title = response.label || 'Link Unlink Delete';
            this.ObjectApiName = response.ObjectApiName;
            this.FieldApiName = response.FieldApiName;

            this.unlinkedRecords = response.unlinkedRecords || [];
            this.linkedRecords = response.linkedRecords || [];

            // Requirement: delete section should show linked records only.
            this.deleteRecords = response.linkedRecords || [];

            this.clearSelections();
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleUnlinkedSelection(event) {
        this.selectedUnlinkedIds = event.detail.selectedRows.map((row) => row.Id);
    }

    handleLinkedSelection(event) {
        this.selectedLinkedIds = event.detail.selectedRows.map((row) => row.Id);
    }

    handleDeleteSelection(event) {
        this.selectedDeleteIds = event.detail.selectedRows.map((row) => row.Id);
    }

    async handleLink() {
        await this.runAction(() => {
            return bulkLink({
                recordIds: this.selectedUnlinkedIds,
                ObjectApiName: this.ObjectApiName,
                FieldApiName: this.FieldApiName,
                parentRecordId: this.recordId
            });
        }, 'Selected records linked successfully.');
    }

    async handleUnlink() {
        await this.runAction(() => {
            return bulkUnlink({
                recordIds: this.selectedLinkedIds,
                ObjectApiName: this.ObjectApiName,
                FieldApiName: this.FieldApiName
            });
        }, 'Selected records unlinked successfully.');
    }

    async handleDelete() {
        if (!window.confirm('Delete selected linked records?')) {
            return;
        }

        await this.runAction(() => {
            return bulkDelete({
                ObjectApiName: this.ObjectApiName
            });
        }, 'Selected records deleted successfully.');
    }

    async runAction(actionCallback, successMessage) {
        this.isLoading = true;

        try {
            const result = await actionCallback();

            if (result.failureCount > 0) {
                this.showToast(
                    'Partial Success',
                    `${result.successCount} succeeded, ${result.failureCount} failed.`,
                    'warning'
                );
            } else {
                this.showToast('Success', successMessage, 'success');
            }

            await this.loadData();
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    clearSelections() {
        this.selectedUnlinkedIds = [];
        this.selectedLinkedIds = [];
        this.selectedDeleteIds = [];
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    getErrorMessage(error) {
        return error?.body?.message || error?.message || 'Unknown error occurred.';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}