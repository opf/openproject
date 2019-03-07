import {Component, OnInit} from "@angular/core";
import {AbstractWidgetComponent} from "app/modules/grids/widgets/abstract-widget.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {TimeEntryDmService} from "core-app/modules/hal/dm-services/time-entry-dm.service";
import {TimeEntryResource} from "core-app/modules/hal/resources/time-entry-resource";
import {TimezoneService} from "core-components/datetime/timezone.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {ConfirmDialogService} from "core-components/modals/confirm-dialog/confirm-dialog.service";
import {formatNumber} from "@angular/common";
import {FilterOperator} from "core-components/api/api-v3/api-v3-filter-builder";

@Component({
  templateUrl: './time-entries-current-user.component.html',
})

export class WidgetTimeEntriesCurrentUserComponent extends AbstractWidgetComponent implements OnInit {
  public text = {
    title: this.i18n.t('js.grid.widgets.time_entries_current_user.title'),
    activity: this.i18n.t('js.time_entry.activity'),
    comment: this.i18n.t('js.time_entry.comment'),
    hour: this.i18n.t('js.time_entry.hours'),
    workPackage: this.i18n.t('js.label_work_package'),
    edit: this.i18n.t('js.button_edit'),
    delete: this.i18n.t('js.button_delete'),
    confirmDelete: {
      text: this.i18n.t('js.text_are_you_sure'),
      title: this.i18n.t('js.modals.form_submit.title')
    },
    noResults: this.i18n.t('js.grid.widgets.time_entries_current_user.no_results'),
  };
  public entries:TimeEntryResource[] = [];
  private entriesLoaded = false;
  public rows:{ date:string, sum?:string, entry?:TimeEntryResource}[] = [];

  constructor(readonly timeEntryDm:TimeEntryDmService,
              readonly timezone:TimezoneService,
              readonly i18n:I18nService,
              readonly pathHelper:PathHelperService,
              readonly confirmDialog:ConfirmDialogService) {
    super(i18n);
  }

  ngOnInit() {
    let filters = [['spentOn', '>t-', ['7']] as [string, FilterOperator, [string]],
                   ['user_id', '=', ['me']] as [string, FilterOperator, [string]]];

    this.timeEntryDm.list({ filters: filters })
      .then((collection) => {
        this.buildEntries(collection.elements);
        this.entriesLoaded = true;
      });
  }

  public get total() {
    let duration = this.entries.reduce((current, entry) => {
      return current + this.timezone.toHours(entry.hours);
    }, 0);

    return this.i18n.t('js.units.hour', { count: this.formatNumber(duration) });
  }

  public get anyEntries() {
    return !!this.entries.length;
  }

  public activityName(entry:TimeEntryResource) {
    return entry.activity.name;
  }

  public projectName(entry:TimeEntryResource) {
    return entry.project.name;
  }

  public workPackageName(entry:TimeEntryResource) {
    return `#${entry.workPackage.idFromLink}: ${entry.workPackage.name}`;
  }

  public workPackageId(entry:TimeEntryResource) {
    return entry.workPackage.idFromLink;
  }

  public comment(entry:TimeEntryResource) {
    return entry.comment;
  }

  public hours(entry:TimeEntryResource) {
    return this.formatNumber(this.timezone.toHours(entry.hours));
  }

  public editPath(entry:TimeEntryResource) {
    return this.pathHelper.timeEntryEditPath(entry.id);
  }

  public deletePath(entry:TimeEntryResource) {
    return this.pathHelper.timeEntryPath(entry.id);
  }

  public workPackagePath(entry:TimeEntryResource) {
    return this.pathHelper.workPackagePath(entry.workPackage.idFromLink);
  }

  public deleteIfConfirmed(event:Event, entry:TimeEntryResource) {
    event.preventDefault();

    this.confirmDialog.confirm({
      text: this.text.confirmDelete,
      closeByEscape: true,
      showClose: true,
      closeByDocument: true
    }).then(() => {
      entry.delete().then(() => {
        let newEntries = this.entries.filter((anEntry) => {
          return entry.id !== anEntry.id;
        });

        this.buildEntries(newEntries);
      });
    })
    .catch(() => {
      // nothing
    });
  }

  private buildEntries(entries:TimeEntryResource[]) {
    this.entries = entries;
    let sumsByDateSpent:{[key:string]:number} = {};

    entries.forEach((entry) => {
      let date = entry.spentOn;

      if (!sumsByDateSpent[date]) {
        sumsByDateSpent[date] = 0;
      }

      sumsByDateSpent[date] = sumsByDateSpent[date] + this.timezone.toHours(entry.hours);
    });

    let sortedEntries = entries.sort((a, b) => {
      return b.spentOn.localeCompare(a.spentOn);
    });

    this.rows = [];
    let currentDate:string|null = null;
    sortedEntries.forEach((entry) => {
      if (entry.spentOn !== currentDate) {
        currentDate = entry.spentOn;
        this.rows.push({date: this.timezone.formattedDate(currentDate!), sum: this.formatNumber(sumsByDateSpent[currentDate!])});
      }

      this.rows.push({date: currentDate!, entry: entry});
    });
    //entries
  }

  private formatNumber(value:number):string {
    try {
      return formatNumber(value, this.i18n.locale, '1.2-2');
    } catch(e) {
      console.error("Failed to format number with Angular (missing locale?): " + e);
      return value.toLocaleString();
    }
  }

  public get noEntries() {
    return !this.entries.length && this.entriesLoaded;
  }
}
