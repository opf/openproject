import { Controller } from '@hotwired/stimulus';
import * as Turbo from '@hotwired/turbo';
import { HttpErrorResponse } from '@angular/common/http';

export default class FormController extends Controller<HTMLFormElement> {
  static values = {
    jobStatusDialogUrl: String,
  };

  declare jobStatusDialogUrlValue:string;

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

  submitForm(evt:CustomEvent) {
    evt.preventDefault(); // Don't submit
    const formatURL = this.element.getAttribute('action');
    const searchParams = this.getExportParams();
    const exportURL = `${formatURL}?${searchParams.toString()}`;
    this.requestExport(exportURL)
      .then((job_id) => this.showJobModal(job_id))
      .catch((error:HttpErrorResponse) => this.handleError(error));
  }

  private handleError(error:HttpErrorResponse) {
    void window.OpenProject.getPluginContext().then((pluginContext) => {
      pluginContext.services.notifications.addError(error);
    });
  }

  private getExportParams() {
    const formData = new FormData(this.element);
    const query = new URLSearchParams(formData.get('query') as string);
    // without the cast to undefined, the URLSearchParams constructor will
    // not accept the FormData object.
    const formParams = new URLSearchParams(formData as unknown as undefined);
    formParams.forEach((value, key) => {
      if (key === 'columns') {
        query.delete('columns[]');
        value.split(' ').forEach((v) => {
          query.append('columns[]', v);
        });
        // Skip hidden fields (looped through query options or rails form fields)
      } else if (!['query', 'utf8', 'authenticity_token'].includes(key)) {
        query.delete(key);
        query.append(key, value);
      }
    });
    return query.toString();
  }
}
