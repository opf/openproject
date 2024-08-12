import { Controller } from '@hotwired/stimulus';

export default class FormController extends Controller<HTMLFormElement> {
  submitForm(evt:CustomEvent) {
    evt.preventDefault(); // Don't submit
    const formatURL = this.element.getAttribute('action');
    const searchParams = this.getExportParams();
    const exportURL = `${formatURL}?${searchParams.toString()}`;
    fetch(exportURL, {
      method: 'GET',
      headers: { Accept: 'application/json' },
      credentials: 'same-origin',
    })
      .then((r) => r.json())
      .then((result:{ job_id:string }) => {
        // TODO: implement with turbo and open job modal
        window.location.href = `/job_statuses/${result.job_id}`;
      })
      .catch((error) => {
        // TODO: error handling
        console.error(error);
      });
  }

  private createSearchParams(params:object) {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, values]) => {
      if (Array.isArray(values)) {
        values.forEach((value:string) => {
          searchParams.append(`${key}[]`, value);
        });
      } else {
        searchParams.append(key, values as string);
      }
    });
    return searchParams;
  }

  private getExportParams() {
    const formData = new FormData(this.element);
    const query = JSON.parse(formData.get('query') as string) as Record<string, unknown>;
    // without the cast to undefined, the URLSearchParams constructor will
    // not accept the FormData object.
    const formParams = new URLSearchParams(formData as unknown as undefined);
    formParams.forEach((value, key) => {
      // Skip hidden fields
      if (!['query', 'utf8', 'authenticity_token'].includes(key)) {
        query[key] = (key === 'columns') ? value.split(' ') : value;
      }
    });
    return this.createSearchParams(query);
  }
}
