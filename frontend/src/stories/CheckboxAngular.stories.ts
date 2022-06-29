import {
  Component,
  EventEmitter,
  Input,
  Output,
} from '@angular/core';

@Component({
  templateUrl: './CheckboxAngular.stories.html',
})
export class CheckboxAngularStoryComponent {
  @Input() disabled = false;

  @Input() name = `spot-checkbox-${+(new Date())}`;

  @Input() public checked = false;

  @Output() checkedChange = new EventEmitter<boolean>();
}
