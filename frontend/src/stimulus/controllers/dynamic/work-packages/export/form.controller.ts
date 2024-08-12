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
          query.append('columns[]', v)
        });
        // Skip hidden fields
      } else if (!['query', 'utf8', 'authenticity_token'].includes(key)) {
        query.delete(key);
        query.append(key, value);
      }
    });
    return query.toString();
  }
}
