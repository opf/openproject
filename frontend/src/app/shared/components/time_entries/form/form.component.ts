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
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';

@Component({
  templateUrl: './form.component.html',
  selector: 'te-form',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TimeEntryFormComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @Input() changeset:ResourceChangeset<TimeEntryResource>;

  @Input() showWorkPackageField = true;

  @Input() showUserField = true;

  @Output() modifiedEntry = new EventEmitter<{ savedResource:TimeEntryResource, isInital:boolean }>();

  @ViewChild('editForm', { static: true }) editForm:EditFormComponent;

  text = {
    wpRequired: this.i18n.t('js.time_entry.work_package_required'),
  };

  public workPackageSelected = false;

  public schema:SchemaResource;

  public customFields:{ key:string, label:string, type:string }[] = [];

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

    this.schema = this.changeset.schema;
    this.workPackageSelected = !!this.changeset?.value('workPackage');
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
      if (/customField\d+/.exec(key) && this.isACustomField(keySchema)) {
        this.customFields.push({ key, label: keySchema.name || '', type: keySchema.type });
      }
    });
  }

  private isACustomField(obj:unknown):obj is IOPFieldSchema {
    return !!(obj as IOPFieldSchema).type;
  }
}
