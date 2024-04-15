import {
  ElementRef,
  Injectable,
} from '@angular/core';
import { ThirdPartyDraggable } from '@fullcalendar/interaction';
import { DragMetaInput } from '@fullcalendar/common';
import { Drake } from 'dragula';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { BehaviorSubject } from 'rxjs';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpWorkPackagesCalendarService } from 'core-app/features/calendar/op-work-packages-calendar.service';
import * as moment from 'moment-timezone';

@Injectable()
export class CalendarDragDropService {
  drake:Drake;

  draggableWorkPackages$ = new BehaviorSubject<WorkPackageResource[]>([]);

  isDragging$ = new BehaviorSubject<string|undefined>(undefined);

  text = {
    draggingDisabled: {
      permissionDenied: this.I18n.t('js.team_planner.modify.errors.permission_denied'),
      fallback: this.I18n.t('js.team_planner.modify.errors.fallback'),
    },
  };

  constructor(
    readonly authorisation:AuthorisationService,
    readonly schemaCache:SchemaCacheService,
    readonly workPackagesCalendarService:OpWorkPackagesCalendarService,
    readonly I18n:I18nService,
  ) {
  }

  destroyDrake():void {
    if (this.drake) {
      this.drake.destroy();
    }
  }

  registerDrag(container:ElementRef, itemSelector:string):void {
    this.drake = dragula({
      containers: [container.nativeElement],
      revertOnSpill: true,
    });

    this.drake.on('drag', (el:HTMLElement) => {
      el.classList.add('gu-transit');
      this.isDragging$.next(el.dataset.dragHelperId);
    });

    this.drake.on('dragend', () => {
      this.isDragging$.next(undefined);
    });

    // eslint-disable-next-line no-new
    new ThirdPartyDraggable(container.nativeElement, {
      itemSelector,
      mirrorSelector: '.gu-mirror', // the dragging element that dragula renders
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      eventData: this.eventData.bind(this),
    });
  }

  handleDrop(workPackage:WorkPackageResource):void {
    this.draggableWorkPackages$
      .next(this
        .draggableWorkPackages$
        .value
        .filter((wp) => wp.id !== workPackage.id));
  }

  handleDropError(workPackage:WorkPackageResource):void {
    const oldDraggables = this.draggableWorkPackages$.value;
    const isElementStillVisible = oldDraggables.filter((wp) => wp.id === workPackage.id).length === 1;

    if (!isElementStillVisible) {
      this.draggableWorkPackages$
        .next(oldDraggables.concat(workPackage));
    }
  }

  workPackageDisabledExplanation(workPackage:WorkPackageResource):string {
    const isDisabled = this.workPackageDisabled(workPackage);

    if (isDisabled.disabled && isDisabled.reason) {
      return isDisabled.reason;
    }

    return '';
  }

  private workPackageDisabled(workPackage:WorkPackageResource):{ disabled:boolean, reason?:string } {
    if (!this.authorisation.can('work_packages', 'editWorkPackage')) {
      return { disabled: true, reason: this.text.draggingDisabled.permissionDenied };
    }

    if (!this.workPackagesCalendarService.dateEditable(workPackage)) {
      return { disabled: true, reason: this.text.draggingDisabled.fallback };
    }

    return { disabled: false };
  }

  private eventData(eventEl:HTMLElement):undefined|DragMetaInput {
    const wpID = eventEl.dataset.dragHelperId;
    if (!wpID) {
      return undefined;
    }

    const workPackage = this.draggableWorkPackages$.value.find((wp) => wp.id === wpID);
    if (!workPackage) {
      return undefined;
    }

    const startDate = moment(workPackage.startDate);
    const dueDate = moment(workPackage.dueDate);
    const duration = Number(moment.duration(workPackage.duration).asDays().toFixed(0));
    const diff = duration > 0 ? duration : dueDate.diff(startDate, 'days') + 1;

    return {
      id: `${workPackage.href as string}-external`,
      title: workPackage.subject,
      duration: {
        days: diff || 1,
      },
      extendedProps: {
        workPackage,
      },
    };
  }
}
