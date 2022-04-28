import {
  Component,
  ChangeDetectionStrategy,
  Input,
  ElementRef,
  HostBinding,
} from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DatasetInputs } from 'core-app/shared/components/dataset-inputs.decorator';

export const opCalendarSidemenuSelector = 'op-calendar-sidemenu';

@DatasetInputs
@Component({
  selector: opCalendarSidemenuSelector,
  templateUrl: './calendar-sidemenu.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CalendarSidemenuComponent extends UntilDestroyedMixin {
  @HostBinding('class.op-sidebar') className = true;

  @Input() menuItems:string[] = [];

  @Input() projectId:string|undefined;

  canCreateCalendar$ = this.currentUserService.hasCapabilities$(
    'calendars/create',
    this.currentProjectService.id || undefined,
  )
    .pipe(this.untilDestroyed());

  text = {
    calendar: this.I18n.t('js.calendar.title'),
    create_new_calendar: this.I18n.t('js.calendar.create_new'),
  };

  createButton = {
    title: this.text.calendar,
    uiSref: 'calendar.page.show',
    uiParams: {
      query_id: null,
      query_props: '',
    },
  };

  constructor(
    readonly elementRef:ElementRef,
    readonly currentUserService:CurrentUserService,
    readonly currentProjectService:CurrentProjectService,
    readonly I18n:I18nService,
  ) {
    super();
  }
}
