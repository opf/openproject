import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {TimeEntryResource} from "core-app/modules/hal/resources/time-entry-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import { ViewEncapsulation, Component, Input, EventEmitter, Output, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { untilComponentDestroyed } from 'ng2-rx-componentdestroyed';
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import { EditFormComponent } from 'core-app/modules/fields/edit/edit-form/edit-form.component';

@Component({
  templateUrl: './form.component.html',
  selector: 'te-form',
  encapsulation: ViewEncapsulation.None
})
export class TimeEntryFormComponent implements OnInit, OnDestroy {
  @Input() entry:TimeEntryResource;

  @Output() modifiedEntry = new EventEmitter<{savedResource:TimeEntryResource, isInital:boolean}>();

  @ViewChild('editForm', { static: true }) editForm:EditFormComponent;

  text = {
    attributes: {
      comment: this.i18n.t('js.time_entry.comment'),
      hours: this.i18n.t('js.time_entry.hours'),
      activity: this.i18n.t('js.time_entry.activity'),
      workPackage: this.i18n.t('js.time_entry.work_package'),
      spentOn: this.i18n.t('js.time_entry.spent_on'),
    },
    wpRequired: this.i18n.t('js.time_entry.work_package_required')
  };

  public workPackageSelected:boolean = false;
  public customFields:{key:string, label:string}[] = [];

  constructor(readonly halEditing:HalResourceEditingService,
              readonly i18n:I18nService) {
  }

  ngOnInit() {
    this.halEditing
      .temporaryEditResource(this.entry)
      .values$()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe(changeset => {
        if (changeset && changeset.workPackage) {
          this.workPackageSelected = true;
        }
      });

    this.setCustomFields(this.entry.schema);
  }

  ngOnDestroy() {
    // nothing to do
  }

  public signalModifiedEntry($event:{savedResource:HalResource, isInital:boolean}) {
    this.modifiedEntry.emit($event as {savedResource:TimeEntryResource, isInital:boolean});
  }
  public save() {
    return this.editForm.save();
  }

  public get inEditMode() {
    return this.entry.isNew;
  }

  private setCustomFields(schema:SchemaResource) {
    Object.entries(schema).forEach(([key, keySchema]) => {
      if (key.match(/customField\d+/)) {
        this.customFields.push({key: key, label: keySchema.name });
      }
    });
  }
}
