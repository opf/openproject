import { Component } from '@angular/core';
import { GridPageComponent } from "core-app/modules/grids/grid/page/grid-page.component";
import { GRID_PROVIDERS } from "core-app/modules/grids/grid/grid.component";

@Component({
  selector: 'overview',
  templateUrl: '../grids/grid/page/grid-page.component.html',
  styleUrls: ['../grids/grid/page/grid-page.component.sass'],
  providers: GRID_PROVIDERS
})
export class OverviewComponent extends GridPageComponent {
  protected i18nNamespace():string {
    return 'overviews';
  }

  protected gridScopePath():string {
    return this.pathHelper.projectPath(this.currentProject.identifier!);
  }
}
