import {
  Component,
  EventEmitter,
  HostBinding,
  Input,
  Output,
} from '@angular/core';

@Component({
  selector: 'spot-filter-chip',
  templateUrl: './filter-chip.component.html',
})
export class SpotFilterChipComponent {
  @HostBinding('class.spot-filter-chip') public className = true;

  @Input() removable = true;
  @Input() title = '';

  @Output() remove = new EventEmitter<void>();
}
