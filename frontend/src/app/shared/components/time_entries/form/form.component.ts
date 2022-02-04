import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Input,
  OnDestroy,
  OnInit,
  Output,
  ViewChild,
  ViewEncapsulation,
} from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { EditFormComponent } from 'core-app/shared/components/fields/edit/edit-form/edit-form.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';

@Component({
  templateUrl: './form.component.html',
  selector: 'te-form',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TimeEntryFormComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @Input() changeset:ResourceChangeset<TimeEntryResource>;

  @Input() showWorkPackageField = true;

  @Output() modifiedEntry = new EventEmitter<{ savedResource:TimeEntryResource, isInital:boolean }>();

  @ViewChild('editForm', { static: true }) editForm:EditFormComponent;

  text = {
    attributes: {
      comment: this.i18n.t('js.time_entry.comment'),
      hours: this.i18n.t('js.time_entry.hours'),
      activity: this.i18n.t('js.time_entry.activity'),
      workPackage: this.i18n.t('js.time_entry.work_package'),
      spentOn: this.i18n.t('js.time_entry.spent_on'),
    },
    wpRequired: this.i18n.t('js.time_entry.work_package_required'),
  };

  public workPackageSelected = false;

  public customFields:{ key:string, label:string }[] = [];

  constructor(readonly halEditing:HalResourceEditingService,
    readonly cdRef:ChangeDetectorRef,
    readonly i18n:I18nService) {
    super();
  }

  ngOnInit() {
    this.halEditing
      .temporaryEditResource(this.changeset.projectedResource)
      .values$()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((changeset) => {
        if (changeset && changeset.workPackage) {
          this.workPackageSelected = true;
          this.cdRef.markForCheck();
        }
      });

    this.setCustomFields();
    this.cdRef.detectChanges();
  }

  public get entry() {
    return this.changeset.projectedResource;
  }

  public signalModifiedEntry($event:{ savedResource:HalResource, isInital:boolean }) {
    this.modifiedEntry.emit($event as { savedResource:TimeEntryResource, isInital:boolean });
  }

  public save() {
    return this.editForm.submit();
  }

  public get inEditMode() {
    // For now, we always want the form in edit mode.
    // Alternatively, this.entry.isNew can be used.
    return true;
  }

  public isRequired(field:string) {
    // Other than defined in the schema, we consider the work package to be required.
    // Remove once the schema requires it explicitly.
    if (field === 'workPackage') {
      return true;
    }
    return this.schema.ofProperty(field).required;
  }

  private setCustomFields() {
    Object.entries(this.schema).forEach(([key, keySchema]) => {
      if (/customField\d+/.exec(key)) {
        this.customFields.push({ key, label: keySchema.name });
      }
    });
  }

  private get schema() {
    return this.changeset.schema;
  }
}
