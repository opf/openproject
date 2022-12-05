import { Component, ViewEncapsulation } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';

/* eslint-disable-next-line change-detection-strategy/on-push */
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
      /* eslint-disable-next-line @typescript-eslint/unbound-method */
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

  onRemoveChip():void {
    /* eslint-disable-next-line no-alert */
    alert('Remove chip');
  }

  checkboxValueString():string {
    if (this.checkboxValue === null) {
      return 'null (indeterminate)';
    }

    if (this.checkboxValue) {
      return 'true (checked)';
    }

    return 'false (unchecked)';
  }

  onUsernameSubmit():void {
    /* eslint-disable-next-line no-alert */
    alert(this.usernameForm.get('username')?.value);
  }
}
