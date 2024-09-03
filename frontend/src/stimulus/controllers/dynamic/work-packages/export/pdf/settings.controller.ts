import { Controller } from '@hotwired/stimulus';

export default class PDFExportSettingsController extends Controller {
  static targets = [
    'fields',
  ];

  declare readonly fieldsTargets:HTMLInputElement[];

  private silenceFormFields(element:HTMLElement, silence:boolean) {
    element.querySelectorAll('input, select').forEach((input:HTMLInputElement) => {
      input.disabled = silence;
    });
  }

  connect() {
    this.fieldsTargets.forEach((element:HTMLElement) => {
      if (element.classList.contains('d-none')) {
        this.silenceFormFields(element, true);
      }
    });
  }

  typeChanged({ params: { name } }:{ params:{ name:string } }) {
    this.fieldsTargets.forEach((element:HTMLElement) => {
      if (element.getAttribute('data-pdf-export-type') === name) {
        element.classList.remove('d-none');
        this.silenceFormFields(element, false);
      } else {
        element.classList.add('d-none');
        this.silenceFormFields(element, true);
      }
    });
  }
}
