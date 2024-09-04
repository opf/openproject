import { Controller } from '@hotwired/stimulus';

export default class DialogController extends Controller {
  static targets = [
    'formatTab', 'submit',
  ];

  declare readonly formatTabTargets:HTMLInputElement[];
  declare readonly submitTarget:HTMLInputElement;

  formatChanged({ params: { format } }:{ params:{ format:string } }) {
    this.formatTabTargets.forEach((element:HTMLElement) => {
      if (element.getAttribute('data-format') === format) {
        element.classList.remove('d-none');
        this.adjustFormSubmitTarget(element);
      } else {
        element.classList.add('d-none');
      }
    });
  }

  private adjustFormSubmitTarget(element:HTMLElement) {
    const form = element.querySelector('form');
    const formID = form?.getAttribute('id') as string;
    this.submitTarget.setAttribute('form', formID);
  }
}
