import {Component} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Title} from '@angular/platform-browser';
import {GridInitializationService} from "core-app/modules/grids/grid/initialization.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {GridPageComponent} from "core-app/modules/grids/grid/page/grid-page.component";
import {GRID_PROVIDERS} from "core-app/modules/grids/grid/grid.component";
import {GridAddWidgetService} from "core-app/modules/grids/grid/add-widget.service";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";

@Component({
  selector: 'dashboard',
  templateUrl: '../../grids/grid/page/grid-page.component.html',
  styleUrls: ['../../grids/grid/page/grid-page.component.sass'],
  providers: GRID_PROVIDERS
})
export class DashboardComponent extends GridPageComponent {
  constructor(readonly gridInitialization:GridInitializationService,
              readonly pathHelper:PathHelperService,
              readonly currentProject:CurrentProjectService,
              readonly i18n:I18nService,
              readonly title:Title,
              readonly addWidget:GridAddWidgetService,
              readonly areas:GridAreaService) {
    super(gridInitialization, pathHelper, i18n, title, addWidget, areas);
  }

  protected i18nNamespace():string {
    return 'dashboards';
  }

  protected gridScopePath():string {
    return this.pathHelper.projectDashboardsPath(this.currentProject.identifier!);
  }
}
