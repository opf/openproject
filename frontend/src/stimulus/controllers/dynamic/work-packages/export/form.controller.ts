import { Controller } from '@hotwired/stimulus';

export default class FormController extends Controller<HTMLFormElement> {
  submitForm(evt:CustomEvent) {
    evt.preventDefault(); // Don't submit
    const formatURL = this.element.getAttribute('action')
    const searchParams = this.getExportParams()
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
      .catch(error => {
        // TODO: error handling
        alert(error.message);
      });
  }

  private createSearchParams(params:Object) {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, values]) => {
      if (Array.isArray(values)) {
        values.forEach((value) => {
          searchParams.append(key + '[]', value);
        });
      } else {
        searchParams.append(key, values);
      }
    });
    return searchParams;
  }

  private getExportParams() {
    const data = new FormData(this.element)
    const query = JSON.parse(data.get('query') as string)
    for (let [key, value] of (data as any)) {
      // Skip hidden fields
      if (['query', 'utf8', 'authenticity_token'].includes(key)) {
        continue
      }
      query[key] = (key === 'columns') ? value.split(' ') : value
    }
    const formatURL = this.element.getAttribute('action')
    return this.createSearchParams(query);
  }
}
