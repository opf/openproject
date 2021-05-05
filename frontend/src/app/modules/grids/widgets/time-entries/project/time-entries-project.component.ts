import { Component, OnInit, Injector, ChangeDetectorRef } from "@angular/core";
import { FilterOperator } from "core-components/api/api-v3/api-v3-filter-builder";
import { WidgetTimeEntriesListComponent } from "core-app/modules/grids/widgets/time-entries/list/time-entries-list.component";
import { TimezoneService } from "core-components/datetime/timezone.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { ConfirmDialogService } from "core-components/modals/confirm-dialog/confirm-dialog.service";
import { CurrentProjectService } from "core-components/projects/current-project.service";

@Component({
  templateUrl: '../list/time-entries-list.component.html',
})
export class WidgetTimeEntriesProjectComponent extends WidgetTimeEntriesListComponent implements OnInit {
  constructor(readonly injector:Injector,
              readonly timezone:TimezoneService,
              readonly i18n:I18nService,
              readonly pathHelper:PathHelperService,
              readonly confirmDialog:ConfirmDialogService,
              protected readonly cdr:ChangeDetectorRef,
              protected readonly currentProject:CurrentProjectService) {
    super(injector, timezone, i18n, pathHelper, confirmDialog, cdr);
  }
  protected dmFilters():Array<[string, FilterOperator, [string]]> {
    return [['spentOn', '>t-', ['7']] as [string, FilterOperator, [string]],
            ['project_id', '=', [this.currentProject.id]] as [string, FilterOperator, [string]]];
  }
}
