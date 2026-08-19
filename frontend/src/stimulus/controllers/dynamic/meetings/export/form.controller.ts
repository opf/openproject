import {Controller} from '@hotwired/stimulus';
import * as Turbo from '@hotwired/turbo';
import {HttpErrorResponse} from '@angular/common/http';
import {useAngularServices, type PickedServices, type ServiceKey} from 'core-stimulus/mixins/use-angular-services';

export default class FormController extends Controller<HTMLFormElement> {
    static services:ServiceKey[] = ['notifications'];

    static values = {
        jobStatusDialogUrl: String,
    };

    static targets = ['inputGroups'];

    declare services:Promise<PickedServices<'notifications'>>;

    declare jobStatusDialogUrlValue:string;
    declare inputGroupsTargets:HTMLElement[];

    initialize() {
        useAngularServices(this);
    }

    jobModalUrl(job_id:string):string {
        return this.jobStatusDialogUrlValue.replace('_job_uuid_', job_id);
    }

    async showJobModal(job_id:string) {
        const response = await fetch(this.jobModalUrl(job_id), {
            method: 'GET',
            headers: {Accept: 'text/vnd.turbo-stream.html'},
        });
        if (response.ok) {
            Turbo.renderStreamMessage(await response.text());
        } else {
            throw new Error(response.statusText);
        }
    }

    async requestExport(exportURL:string):Promise<string> {
        const response = await fetch(exportURL, {
            method: 'GET',
            headers: {Accept: 'application/json'},
            credentials: 'same-origin',
        });
        if (!response.ok) {
            throw new Error(`HTTP ${response.status.toString()}: ${response.statusText}`);
        }
        const result = await response.json() as { job_id:string };
        if (!result.job_id) {
            throw new Error(I18n.t('js.invalid_job_response'));
        }
        return result.job_id;
    }

    generateExportURL(formData:FormData):string {
        const actionURL = this.element.getAttribute('action') ?? '';
        const searchParams = this.getExportParams(formData);
        const append = actionURL.includes('?') ? '&' : '?';
        return `${actionURL}${append}${searchParams}`;
    }

    submitForm(evt:CustomEvent) {
        evt.preventDefault(); // Don't submit
        const formData = new FormData(this.element);
        this.requestExport(this.generateExportURL(formData))
            .then((job_id) => this.showJobModal(job_id))
            .catch((error:unknown) => {
                void this.handleError(error);
            });
        return true;
    }

    private async handleError(error:unknown) {
        const {notifications} = await this.services;
        notifications.addError(error as HttpErrorResponse);
    }

    private getExportParams(formData:FormData):string {
        const formParams = new URLSearchParams(formData as unknown as undefined);
        const query = new URLSearchParams();
        // Remove duplicate parameters inserted by Primer::Checkbox (two inputs per checkbox)
        formParams.forEach((value, key) => {
            query.delete(key);
            query.append(key, value);
        });
        return query.toString();
    }

    templatesChanged({params: {name}}:{ params:{ name:string } }) {
        this.inputGroupsTargets.forEach((inputGroup:HTMLElement) => {
            inputGroup.classList.toggle('d-none', inputGroup.dataset.template !== name);
        });
    }
}
