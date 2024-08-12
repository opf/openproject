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
    const data:FormData = new FormData(this.element);
    const query = JSON.parse(data.get('query') as string);
    // "dom.iterable" nor "dom" is defined in tsjonfig.
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access no-explicit-any
    (data as any).entries().forEach(([key, value]:[string, string]) => {
      // Skip hidden fields
      if (!['query', 'utf8', 'authenticity_token'].includes(key)) {
        query[key] = (key === 'columns') ? value.split(' ') : value;
      }
    });
    return this.createSearchParams(query);
  }
}
