import {Component} from '@angular/core';
import {GridPageComponent} from "core-app/modules/grids/grid/page/grid-page.component";
import {GRID_PROVIDERS} from "core-app/modules/grids/grid/grid.component";

@Component({
  selector: 'dashboard',
  templateUrl: '../../grids/grid/page/grid-page.component.html',
  styleUrls: ['../../grids/grid/page/grid-page.component.sass'],
  providers: GRID_PROVIDERS
})
export class DashboardComponent extends GridPageComponent {
  protected i18nNamespace():string {
    return 'dashboards';
  }

  protected gridScopePath():string {
    return this.pathHelper.projectDashboardsPath(this.currentProject.identifier!);
  }
}
