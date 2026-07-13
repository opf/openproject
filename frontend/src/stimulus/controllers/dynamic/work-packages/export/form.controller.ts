import { Controller } from '@hotwired/stimulus';
import * as Turbo from '@hotwired/turbo';
import { HttpErrorResponse } from '@angular/common/http';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

export default class FormController extends Controller<HTMLFormElement> {
  static services:ServiceKey[] = ['notifications'];

  static values = {
    jobStatusDialogUrl: String,
    jobStatusDialogId: String,
  };

  declare services:Promise<PickedServices<'notifications'>>;

  declare jobStatusDialogUrlValue:string;
  declare jobStatusDialogIdValue:string;

  initialize() {
    useAngularServices(this);
  }

  jobModalUrl(job_id:string):string {
    return this.jobStatusDialogUrlValue.replace('_job_uuid_', job_id);
  }

  async showJobModal(job_id:string) {
    const response = await fetch(this.jobModalUrl(job_id), {
      method: 'GET',
      headers: { Accept: 'text/vnd.turbo-stream.html' },
    });
    if (response.ok) {
      Turbo.renderStreamMessage(await response.text());
    } else {
      throw new Error(response.statusText || 'Invalid response from server');
    }
  }

  async requestExport(exportURL:string):Promise<string> {
    const response = await fetch(exportURL, {
      method: 'GET',
      headers: { Accept: 'application/json' },
      credentials: 'same-origin',
    });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    const result = await response.json() as { job_id:string };
    if (!result.job_id) {
      throw new Error('Invalid response from server');
    }
    return result.job_id;
  }

  generateExportURL(formData:FormData):string {
    const actionURL = this.element.getAttribute('action')!;
    const searchParams = this.getExportParams(formData);
    const append = actionURL.includes('?') ? '&' : '?';
    return `${actionURL}${append}${searchParams.toString()}`;
  }

  submitForm(evt:CustomEvent) {
    evt.preventDefault(); // Don't submit
    const formData = new FormData(this.element);

    const columns = formData.get('columns');
    if (!columns && this.mustHaveColumns(formData)) {
      return false; // Error is already displayed on the element
    }

    const saveExportSettingsCheckbox = document.getElementById('op-work-packages-export-dialog-form-save_export_settings') as HTMLInputElement;
    if (saveExportSettingsCheckbox) {
      formData.set('save_export_settings', saveExportSettingsCheckbox.checked ? 'true' : 'false');
    }

    this.requestExport(this.generateExportURL(formData))
      .then((job_id) => this.showJobModal(job_id))
      .catch((error:HttpErrorResponse) => { void this.handleError(error); });

    const dialog = document.getElementById(this.jobStatusDialogIdValue) as HTMLDialogElement;
    if (dialog) {
      dialog.close();
    }

    return true;
  }

  private async handleError(error:HttpErrorResponse) {
    const { notifications } = await this.services;
    notifications.addError(error);
  }

  private findCurrentVisibleColumnSelection(formData:FormData):HTMLElement|null {
    const format = formData.get('format') as string;
    if (format === 'pdf') {
      // find the currently visible section (we have several columns on the form)
      const pdfExportType = formData.get('pdf_export_type') as string;
      return this.element.querySelector(`[data-pdf-export-type="${pdfExportType}"] [data-columns-selection]`)!;
    }
    return this.element.querySelector('[data-columns-selection]')!;
  }

  private mustHaveColumns(formData:FormData):boolean {
    // find the column selector
    const columnsElement = this.findCurrentVisibleColumnSelection(formData);
    if (!columnsElement) {
      return false;
    }
    return columnsElement.dataset.required === 'true';
  }

  private getExportParams(formData:FormData):string {
    const query = new URLSearchParams(formData.get('query') as string);
    // without the cast to undefined, the URLSearchParams constructor will
    // not accept the FormData object.
    const formParams = new URLSearchParams(formData as unknown as undefined);
    formParams.forEach((value, key) => {
      if (key === 'columns') {
        query.delete('columns[]'); // deletes all occurrences of columns[]
        const columns = value.split(' ');
        columns.forEach((v) => {
          query.append('columns[]', v);
        });
        if (columns.length === 0 || value === '') {
          // add special parameter to indicate no columns
          // for an empty columns array the default columns would be used
          query.append('no_columns', '1');
        }
        // Skip hidden fields (looped through query options or rails form fields)
      } else if (!['query', 'utf8', 'authenticity_token', 'format'].includes(key)) {
        query.delete(key);
        query.append(key, value);
      }
    });
    return query.toString();
  }
}
