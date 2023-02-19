import {
  Component,
  EventEmitter,
  Input,
  Output,
} from '@angular/core';

@Component({
  templateUrl: './SwitchAngular.html',
})
export class SwitchAngularStoryComponent {
  @Input() disabled = false;

  @Input() name = `spot-switch-${+(new Date())}`;

  @Input() public checked = false;

  @Output() checkedChange = new EventEmitter<boolean>();
}
