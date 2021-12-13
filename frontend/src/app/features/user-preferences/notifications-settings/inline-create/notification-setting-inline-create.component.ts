import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  Input,
  Output,
} from '@angular/core';
import { FormArray } from '@angular/forms';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { HalSourceLink } from 'core-app/features/hal/resources/hal-resource';
import { UserPreferencesQuery } from 'core-app/features/user-preferences/state/user-preferences.query';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';

export interface NotificationSettingProjectOption {
  name:string;
  href:string;
}

@Component({
  selector: 'op-notification-setting-inline-create',
  templateUrl: './notification-setting-inline-create.component.html',
  styleUrls: ['./notification-setting-inline-create.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationSettingInlineCreateComponent {
  @Input() userId:string;

  @Input() settings:FormArray;

  @Output() selected = new EventEmitter<HalSourceLink>();

  /** Active inline-create mode */
  active = false;

  text = {
    add_setting: this.I18n.t('js.notifications.settings.project_specific.add'),
    please_select: this.I18n.t('js.placeholders.selection'),
    already_selected: this.I18n.t('js.notifications.settings.project_specific.already_selected'),
  };

  public autocompleterOptions = {
    filters: [],
    resource: 'default',
    getOptionsFn: (query:string):Observable<unknown[]> => this.autocomplete(query),
  };

  constructor(
    private I18n:I18nService,
    private apiV3Service:ApiV3Service,
  ) {
  }

  selectProject($event:NotificationSettingProjectOption):void {
    this.selected.emit({ title: $event.name, href: $event.href });
    this.active = false;
  }

  private autocomplete(term:string|null):Observable<NotificationSettingProjectOption[]> {
    const filters = new ApiV3FilterBuilder()
      .add('visible', '=', [this.userId]);

    if (term) {
      filters.add('name_and_identifier', '~', [term]);
    }

    return this
      .apiV3Service
      .projects
      .filtered(filters)
      .get()
      .pipe(
        map((collection) => collection.elements.map((project) => ({
          href: project.href || '',
          name: (project.parent ? '... ' : '') + project.name,
          disabled: !!this.settings.controls.find(
            (projectSetting) => (projectSetting.get('project')!.value as NotificationSettingProjectOption).href === project.href,
          ),
        }))),
      );
  }
}
