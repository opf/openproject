import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  Input,
  OnInit
} from "@angular/core";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {TimeEntryEditService} from "core-app/modules/time_entries/edit/edit.service";
import {TimeEntryCacheService} from "core-components/time-entries/time-entry-cache.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {TimeEntryResource} from "core-app/modules/hal/resources/time-entry-resource";

export const triggerEditEntryComponentSelector = 'time-entry--trigger-edit-entry';

@Component({
  selector: triggerEditEntryComponentSelector,
  template: `
    <a *ngIf="entry"
       (click)="editTimeEntry(entry)"
       [title]="text.edit"
       class="no-decoration-on-hover">
      <op-icon icon-classes="icon-context icon-edit"></op-icon>
    </a>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TriggerEditEntryComponent implements OnInit {
  @InjectField() public readonly timeEntryEditService:TimeEntryEditService;
  @InjectField() public readonly timeEntryCache:TimeEntryCacheService;
  @InjectField() readonly elementRef:ElementRef;
  @InjectField() readonly i18n:I18nService;
  @InjectField() readonly cdRef:ChangeDetectorRef;

  public entry:TimeEntryResource;

  public text = {
    edit: this.i18n.t('js.button_edit'),
  };

  constructor(readonly injector:Injector) {

  }

  ngOnInit() {
    let timeEntryId = this.elementRef.nativeElement.dataset['entry'];
    this.timeEntryCache
      .require(timeEntryId)
      .then((loadedEntry) => {
        this.entry = loadedEntry;
        this.cdRef.detectChanges();
      });
  }

  editTimeEntry(entry:TimeEntryResource) {
    this.timeEntryEditService
      .edit(entry)
      .then(() => {
        window.location.reload();
      })
      .catch(() => {
        // User canceled the modal
      });
  }
}