import { Component, ViewEncapsulation } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';

@Component({
  selector: 'spot-docs',
  templateUrl: './spot-docs.component.html',
  styleUrls: ['./spot-docs.component.sass'],
  encapsulation: ViewEncapsulation.None,
})
export class SpotDocsComponent {
  indeterminateState = null;

  checkboxValue = null;

  listCheckboxValue = null;

  textFieldValue = 'ngModel value';

  usernameForm = new FormGroup({
    username: new FormControl('', [
      Validators.required,
      Validators.minLength(3),
      Validators.maxLength(5),
    ]),
  });

  dropModalOpen = false;

  dropModalAlignment = 'bottom-left';

  tooltipAlignment = 'right-center';

  toggleValue = null;

  toggleOptions = [
    { value: 1, title: '1' },
    { value: 2, title: '2' },
    { value: 3, title: '3' },
  ];

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

  onUsernameSubmit() {
    alert(this.usernameForm.get('username')?.value);
  }
}
