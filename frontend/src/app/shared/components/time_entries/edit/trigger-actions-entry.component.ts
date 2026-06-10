import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Injector, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { Observable, switchMap } from 'rxjs';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

@Component({
  selector: 'opce-time-entry-trigger-actions',
  template: `
    <a (click)="editTimeEntry()"
       [title]="text.edit"
       class="no-decoration-on-hover">
      <op-icon icon-classes="icon-context icon-edit" />
    </a>
    <a (click)="deleteTimeEntry()"
       [title]="text.delete"
       class="no-decoration-on-hover">
      <op-icon icon-classes="icon-context icon-delete" />
    </a>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService,
    PathHelperService,
    TurboRequestsService,
  ],
  standalone: false,
})
export class TriggerActionsEntryComponent {
  readonly injector = inject(Injector);

  readonly apiv3Service = inject(ApiV3Service);

  readonly toastService = inject(ToastService);

  readonly elementRef = inject(ElementRef);

  readonly i18n = inject(I18nService);

  readonly cdRef = inject(ChangeDetectorRef);

  readonly pathHelper = inject(PathHelperService);

  readonly turboRequestService = inject(TurboRequestsService);

  public text = {
    edit: this.i18n.t('js.button_edit'),
    delete: this.i18n.t('js.button_delete'),
    error: this.i18n.t('js.error.internal'),
    areYouSure: this.i18n.t('js.text_are_you_sure'),
  };

  editTimeEntry() {
    void this.loadEntry().subscribe((entry:TimeEntryResource) => {
      document.addEventListener('dialog:close', (event:CustomEvent) => {
        const { detail: { dialog, submitted } } = event as { detail:{ dialog:HTMLDialogElement, submitted:boolean } };
        if (dialog.id === 'time-entry-dialog' && submitted) {
          window.location.reload();
        }
      });
      void this.turboRequestService.request(
        this.pathHelper.timeEntryEditDialog(entry.id!),
        { method: 'GET' },
      );
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
    const timeEntryId = (this.elementRef.nativeElement as HTMLElement).dataset.entry!;

    return this
      .apiv3Service
      .time_entries
      .id(timeEntryId)
      .get();
  }
}
