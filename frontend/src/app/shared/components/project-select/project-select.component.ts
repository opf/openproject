import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
} from '@angular/core';

@Component({
  selector: 'op-project-select',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-select.component.html',
})
export class OpProjectSelectComponent {
  public open = false;
  public searchText = '';

  constructor(
    readonly I18n:I18nService,
    protected cdRef:ChangeDetectorRef,
  ) { }
}
