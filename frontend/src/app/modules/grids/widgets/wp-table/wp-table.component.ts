import {Component, OnInit, OnDestroy, ViewChild, AfterViewInit} from "@angular/core";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {WidgetWpListComponent} from "core-app/modules/grids/widgets/wp-widget/wp-widget.component";
import {WorkPackageTableConfiguration} from "core-components/wp-table/wp-table-configuration";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {WorkPackageIsolatedQuerySpaceDirective} from "core-app/modules/work_packages/query-space/wp-isolated-query-space.directive";

@Component({
  templateUrl: '../wp-widget/wp-widget.component.html',
  styleUrls: ['../wp-widget/wp-widget.component.css']
})
export class WidgetWpTableComponent extends WidgetWpListComponent implements OnInit, OnDestroy, AfterViewInit {
  public text = { title: this.i18n.t('js.grid.widgets.work_packages_table.title') };
  public queryProps = {};

  public configuration:Partial<WorkPackageTableConfiguration> = {
    actionsColumnEnabled: false,
    columnMenuEnabled: true,
    hierarchyToggleEnabled: true,
    contextMenuEnabled: false
  };

  @ViewChild(WorkPackageIsolatedQuerySpaceDirective) public querySpaceDirective:WorkPackageIsolatedQuerySpaceDirective;

  ngOnInit() {
    super.ngOnInit();

  }

  ngAfterViewInit() {
    this
      .querySpaceDirective
      .querySpace
      .query
      .values$()
      .pipe(
        untilComponentDestroyed(this)
      ).subscribe(() => console.log('query updated'));
  }

  ngOnDestroy() {
    // nothing to do
  }
}
