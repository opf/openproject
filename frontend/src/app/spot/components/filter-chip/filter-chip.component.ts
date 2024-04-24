import {
  Component,
  EventEmitter,
  HostBinding,
  Input,
  Output,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  selector: 'spot-filter-chip',
  templateUrl: './filter-chip.component.html',
})
export class SpotFilterChipComponent {
  @HostBinding('class.spot-filter-chip') public className = true;

  @Input() @HostBinding('class.spot-filter-chip_disabled') public disabled = false;

  @Input() removable = true;

  @Input() title = '';

  @Input() icon = '';

  @Output() remove = new EventEmitter<void>();

  public text = {
    remove: this.i18n.t('js.spot.filter_chip.remove'),
  };

  public get iconClasses():string[] {
    return [
      'spot-icon',
      `spot-icon_${this.icon}`,
    ];
  }

  constructor(readonly i18n:I18nService) {}
}
