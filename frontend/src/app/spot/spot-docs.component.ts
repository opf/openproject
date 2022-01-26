import { Component } from '@angular/core';

@Component({
  selector: 'spot-docs',
  templateUrl: './spot-docs.component.html',
})
export class SpotDocsComponent {
  indeterminateState = null;
  checkboxValue = null;
  textFieldValue = 'ngModel value';
  dropModalOpen = false;

  onRemoveChip() {
    alert('Remove chip');
  }

  checkboxValueString() {
    if (this.checkboxValue === null) {
      return 'null (indeterminate)';
    }

    if (this.checkboxValue) {
      return 'true (checked)';
    }

    return 'false (unchecked)';
  }
}
