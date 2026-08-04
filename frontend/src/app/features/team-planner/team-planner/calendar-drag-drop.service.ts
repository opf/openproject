import { ElementRef, Injectable, inject } from '@angular/core';
import { Draggable } from '@fullcalendar/interaction';
import { DragMetaInput, PointerDragEvent } from '@fullcalendar/core/internal';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { BehaviorSubject } from 'rxjs';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpWorkPackagesCalendarService } from 'core-app/features/calendar/op-work-packages-calendar.service';
import moment from 'moment-timezone';

@Injectable()
export class CalendarDragDropService {
  readonly authorisation = inject(AuthorisationService);
  readonly schemaCache = inject(SchemaCacheService);
  readonly workPackagesCalendarService = inject(OpWorkPackagesCalendarService);
  readonly I18n = inject(I18nService);

  private draggable:Draggable|undefined;

  private draggedElement:HTMLElement|undefined;

  draggableWorkPackages$ = new BehaviorSubject<WorkPackageResource[]>([]);

  isDragging$ = new BehaviorSubject<string|undefined>(undefined);

  text = {
    draggingDisabled: {
      permissionDenied: this.I18n.t('js.team_planner.modify.errors.permission_denied'),
      fallback: this.I18n.t('js.team_planner.modify.errors.fallback'),
    },
  };

  destroyDraggable():void {
    this.draggable?.destroy();
    this.draggable = undefined;
  }

  registerDrag(container:ElementRef<HTMLElement>, itemSelector:string):void {
    this.destroyDraggable();

    this.draggable = new Draggable(container.nativeElement, {
      itemSelector,
      eventData: this.eventData.bind(this),
    });

    // `dragging` is typed public but undocumented: FullCalendar treats the
    // pointer-drag engine as internal, so an upgrade may move or rename it.
    const { emitter } = this.draggable.dragging;

    emitter.on('dragstart', (ev:PointerDragEvent) => {
      this.draggedElement = ev.subjectEl as HTMLElement;
      this.draggedElement.classList.add('op-add-existing-pane--wp_dragging');
      this.isDragging$.next(this.draggedElement.dataset.dragHelperId);
    });

    // A mid-drag destroy() delivers a dragend without subjectEl, so the
    // dragged element is tracked in a field instead.
    emitter.on('dragend', () => {
      this.draggedElement?.classList.remove('op-add-existing-pane--wp_dragging');
      this.draggedElement = undefined;
      this.isDragging$.next(undefined);
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
      id: `${workPackage.href!}-external`,
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
