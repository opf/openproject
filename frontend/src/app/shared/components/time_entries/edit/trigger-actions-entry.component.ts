import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Injector } from '@angular/core';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { TimeEntryEditService } from 'core-app/shared/components/time_entries/edit/edit.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { Observable, switchMap } from 'rxjs';

@Component({
  selector: 'opce-time-entry-trigger-actions',
  template: `
    <a (click)="editTimeEntry()"
       [title]="text.edit"
       class="no-decoration-on-hover">
      <op-icon icon-classes="icon-context icon-edit"></op-icon>
    </a>
    <a (click)="deleteTimeEntry()"
       [title]="text.delete"
       class="no-decoration-on-hover">
      <op-icon icon-classes="icon-context icon-delete"></op-icon>
    </a>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService,
    TimeEntryEditService,
  ],
})
export class TriggerActionsEntryComponent {
  @InjectField() readonly timeEntryEditService:TimeEntryEditService;

  @InjectField() readonly apiv3Service:ApiV3Service;

  @InjectField() readonly toastService:ToastService;

  @InjectField() readonly elementRef:ElementRef;

  @InjectField() i18n!:I18nService;

  @InjectField() readonly cdRef:ChangeDetectorRef;

  public text = {
    edit: this.i18n.t('js.button_edit'),
    delete: this.i18n.t('js.button_delete'),
    error: this.i18n.t('js.error.internal'),
    areYouSure: this.i18n.t('js.text_are_you_sure'),
  };

  constructor(readonly injector:Injector) {
  }

  editTimeEntry() {
    void this
      .loadEntry()
      .subscribe((entry) => {
        this.timeEntryEditService
          .edit(entry)
          .then(() => {
            window.location.reload();
          })
          .catch(() => {
            // User canceled the modal
          });
      });
  }

  deleteTimeEntry() {
    if (!window.confirm(this.text.areYouSure)) {
      return;
    }

    this.loadEntry()
      .pipe(
        switchMap((entry) => this
          .apiv3Service
          .time_entries
          .id(entry)
          .delete()),
      )
      .subscribe(
        () => window.location.reload(),
        (error) => this.toastService.addError(error || this.text.error),
      );
  }

  protected loadEntry():Observable<TimeEntryResource> {
    const timeEntryId = (this.elementRef.nativeElement as HTMLElement).dataset.entry as string;

    return this
      .apiv3Service
      .time_entries
      .id(timeEntryId)
      .get();
  }
}
