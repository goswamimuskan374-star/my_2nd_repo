import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';

import getLeads from '@salesforce/apex/LeadRecordController.getLeads';
import getAccounts from '@salesforce/apex/LeadRecordController.getAccounts';

const LEAD_COLUMNS = [
    {
        label: 'Lead Name',
        fieldName: 'Name',
        type: 'text',
        sortable: true
    },
    {
        label: 'Company',
        fieldName: 'Company',
        type: 'text',
        sortable: true
    },
    {
        label: 'Status',
        fieldName: 'Status',
        type: 'text',
        sortable: true
    },
    {
        label: 'Phone',
        fieldName: 'Phone',
        type: 'phone'
    },
    {
        label: 'Email',
        fieldName: 'Email',
        type: 'email'
    },
    {
        type: 'button',
        fixedWidth: 100,
        typeAttributes: {
            label: 'View',
            name: 'viewLead',
            variant: 'brand'
        }
    }
];

const ACCOUNT_COLUMNS = [
    {
        label: 'Account Name',
        fieldName: 'Name',
        type: 'text',
        sortable: true
    },
    {
        label: 'Phone',
        fieldName: 'Phone',
        type: 'phone'
    },
    {
        label: 'Industry',
        fieldName: 'Industry',
        type: 'text',
        sortable: true
    },
    {
        label: 'Website',
        fieldName: 'Website',
        type: 'url',
        typeAttributes: {
            target: '_blank'
        }
    },
    {
        label: 'Type',
        fieldName: 'Type',
        type: 'text',
        sortable: true
    },
    {
        type: 'button',
        fixedWidth: 100,
        typeAttributes: {
            label: 'View',
            name: 'viewAccount',
            variant: 'brand'
        }
    }
];

export default class LeadList extends LightningElement {

    // Columns
    leadColumns = LEAD_COLUMNS;
    accountColumns = ACCOUNT_COLUMNS;

    // Loading
    isLoading = true;

    // Lead Data
    leads = [];
    filteredLeads = [];
    leadWireResult;

    // Account Data
    accounts = [];
    filteredAccounts = [];
    accountWireResult;

    // Sorting
    leadSortBy;
    leadSortDirection = 'asc';

    accountSortBy;
    accountSortDirection = 'asc';

    // Modal
    showLeadModal = false;
    showAccountModal = false;

    selectedLead = {};
    selectedAccount = {};

    // Total Records
    get totalLeadRecords() {
        return this.filteredLeads.length;
    }

    get totalAccountRecords() {
        return this.filteredAccounts.length;
    }

    // ==========================
    // Leads
    // ==========================
    @wire(getLeads)
    wiredLeads(result) {

        this.leadWireResult = result;

        if (result.data) {

            this.leads = [...result.data];
            this.filteredLeads = [...result.data];

            this.isLoading = false;

        } else if (result.error) {

            console.error(result.error);
            this.isLoading = false;

        }

    }

    // ==========================
    // Accounts
    // ==========================
    @wire(getAccounts)
    wiredAccounts(result) {

        this.accountWireResult = result;

        if (result.data) {

            this.accounts = [...result.data];
            this.filteredAccounts = [...result.data];

        } else if (result.error) {

            console.error(result.error);

        }

    }
        // ==========================
    // Lead Search
    // ==========================
    handleLeadSearch(event) {

        const searchKey = event.target.value.toLowerCase().trim();

        if (!searchKey) {
            this.filteredLeads = [...this.leads];
            return;
        }

        this.filteredLeads = this.leads.filter(record =>
            (record.Name || '').toLowerCase().includes(searchKey) ||
            (record.Company || '').toLowerCase().includes(searchKey) ||
            (record.Status || '').toLowerCase().includes(searchKey) ||
            (record.Phone || '').toLowerCase().includes(searchKey) ||
            (record.Email || '').toLowerCase().includes(searchKey)
        );

    }

    // ==========================
    // Account Search
    // ==========================
    handleAccountSearch(event) {

        const searchKey = event.target.value.toLowerCase().trim();

        if (!searchKey) {
            this.filteredAccounts = [...this.accounts];
            return;
        }

        this.filteredAccounts = this.accounts.filter(record =>
            (record.Name || '').toLowerCase().includes(searchKey) ||
            (record.Phone || '').toLowerCase().includes(searchKey) ||
            (record.Industry || '').toLowerCase().includes(searchKey) ||
            (record.Type || '').toLowerCase().includes(searchKey) ||
            (record.Website || '').toLowerCase().includes(searchKey)
        );

    }

    // ==========================
    // Refresh
    // ==========================
    handleLeadRefresh() {

        this.isLoading = true;

        refreshApex(this.leadWireResult)
            .finally(() => {
                this.isLoading = false;
            });

    }

    handleAccountRefresh() {

        this.isLoading = true;

        refreshApex(this.accountWireResult)
            .finally(() => {
                this.isLoading = false;
            });

    }

    // ==========================
    // Lead Sorting
    // ==========================
    doLeadSorting(event) {

        this.leadSortBy = event.detail.fieldName;
        this.leadSortDirection = event.detail.sortDirection;

        let data = [...this.filteredLeads];

        data.sort((a, b) => {

            let x = a[this.leadSortBy] || '';
            let y = b[this.leadSortBy] || '';

            x = typeof x === 'string' ? x.toLowerCase() : x;
            y = typeof y === 'string' ? y.toLowerCase() : y;

            return this.leadSortDirection === 'asc'
                ? (x > y ? 1 : x < y ? -1 : 0)
                : (x < y ? 1 : x > y ? -1 : 0);

        });

        this.filteredLeads = data;

    }

    // ==========================
    // Account Sorting
    // ==========================
    doAccountSorting(event) {

        this.accountSortBy = event.detail.fieldName;
        this.accountSortDirection = event.detail.sortDirection;

        let data = [...this.filteredAccounts];

        data.sort((a, b) => {

            let x = a[this.accountSortBy] || '';
            let y = b[this.accountSortBy] || '';

            x = typeof x === 'string' ? x.toLowerCase() : x;
            y = typeof y === 'string' ? y.toLowerCase() : y;

            return this.accountSortDirection === 'asc'
                ? (x > y ? 1 : x < y ? -1 : 0)
                : (x < y ? 1 : x > y ? -1 : 0);

        });

        this.filteredAccounts = data;

    }

    // ==========================
    // Lead View
    // ==========================
    handleLeadRowAction(event) {

        const action = event.detail.action.name;

        if (action === 'viewLead') {

            this.selectedLead = event.detail.row;
            this.showLeadModal = true;

        }

    }

    // ==========================
    // Account View
    // ==========================
    handleAccountRowAction(event) {

        const action = event.detail.action.name;

        if (action === 'viewAccount') {

            this.selectedAccount = event.detail.row;
            this.showAccountModal = true;

        }

    }

    // ==========================
    // Close Modals
    // ==========================
    closeLeadModal() {

        this.showLeadModal = false;
        this.selectedLead = {};

    }

    closeAccountModal() {

        this.showAccountModal = false;
        this.selectedAccount = {};

    }

}