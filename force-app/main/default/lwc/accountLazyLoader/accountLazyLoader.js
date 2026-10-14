import { LightningElement } from 'lwc';
import getAccounts from '@salesforce/apex/AccountLazyLoader.getAccounts';

export default class AccountLazyLoader extends LightningElement {

    accounts = [];
    pageSize = 10;
    offsetValue = 0;

    isLoading = false;
    allLoaded = false;

    connectedCallback() {
        this.loadAccounts();
    }

    loadAccounts() {

        if (this.isLoading || this.allLoaded) {
            return;
        }

        this.isLoading = true;

        getAccounts({
            offsetValue: this.offsetValue,
            pageSize: this.pageSize
        })
        .then(result => {

            console.log('Accounts returned:', result.length);

            this.accounts = [
                ...this.accounts,
                ...result
            ];

            this.offsetValue += result.length;

            if (result.length < this.pageSize) {
                this.allLoaded = true;
            }
        })
        .catch(error => {
            console.error('Account error:', error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleScroll(event) {

        const container = event.target;

        const nearBottom =
            container.scrollTop + container.clientHeight >=
            container.scrollHeight - 50;

        if (
            nearBottom &&
            !this.isLoading &&
            !this.allLoaded
        ) {

            this.isLoading = true;

            setTimeout(() => {

                getAccounts({
                    offsetValue: this.offsetValue,
                    pageSize: this.pageSize
                })
                .then(result => {

                    console.log(
                        'Next accounts returned:',
                        result.length
                    );

                    this.accounts = [
                        ...this.accounts,
                        ...result
                    ];

                    this.offsetValue += result.length;

                    if (result.length < this.pageSize) {
                        this.allLoaded = true;
                    }

                })
                .catch(error => {
                    console.error('Next page error:', error);
                })
                .finally(() => {
                    this.isLoading = false;
                });

            }, 2000);
        }
    }
}