import { Component } from "@angular/core";
import { GRID_PROVIDERS } from "core-app/modules/grids/grid/grid.component";
import { GridPageComponent } from "core-app/modules/grids/grid/page/grid-page.component";

@Component({
  templateUrl: '../grids/grid/page/grid-page.component.html',
  styleUrls: ['../grids/grid/page/grid-page.component.sass'],
  providers: GRID_PROVIDERS
})
export class MyPageComponent extends GridPageComponent {
  protected i18nNamespace():string {
    return 'my_page';
  }

  protected gridScopePath():string {
    return this.pathHelper.myPagePath();
  }
}
