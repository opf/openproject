import {
  EventEmitter, Component, OnInit, ChangeDetectionStrategy, Output, Input,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Observable, of } from 'rxjs';
import { map, tap } from 'rxjs/operators';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { HalSourceLink } from 'core-app/features/hal/resources/hal-resource';

export interface NotificationSettingProjectOption {
  name:string;
  href:string;
}

@Component({
  selector: 'op-notification-setting-inline-create',
  templateUrl: './notification-setting-inline-create.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationSettingInlineCreateComponent {
  @Input() userId:string;

  @Output() onSelect = new EventEmitter<HalSourceLink>();

  /** Active inline-create mode */
  active = false;

  text = {
    add_setting: this.I18n.t('js.notifications.settings.add'),
    please_select: this.I18n.t('js.placeholders.selection'),
  };

  public autocompleterOptions = {
    filters: [],
    resource: 'default',
    getOptionsFn: (query:string):Observable<any[]> => this.autocomplete(query),
  };

  constructor(
    private I18n:I18nService,
    private apiV3Service:APIV3Service,
  ) {
  }

  selectProject($event:NotificationSettingProjectOption) {
    this.onSelect.emit({ title: $event.name, href: $event.href });
    this.active = false;
  }

  private autocomplete(term:string):Observable<NotificationSettingProjectOption[]> {
    if (!term) {
      return of([]);
    }

    const filters = new ApiV3FilterBuilder()
      .add('name_and_identifier', '~', [term])
      .add('visible', '=', [this.userId]);

    return this
      .apiV3Service
      .projects
      .filtered(filters)
      .get()
      .pipe(
        map((collection) => collection.elements.map((project) => ({ href: project.href!, name: project.name }))),
      );
  }
}
