import { Component } from '@angular/core';
import { GridPageComponent } from 'core-app/shared/components/grids/grid/page/grid-page.component';
import { GRID_PROVIDERS } from 'core-app/shared/components/grids/grid/grid.component';

@Component({
  selector: 'overview',
  templateUrl: '../../shared/components/grids/grid/page/grid-page.component.html',
  styleUrls: ['../../shared/components/grids/grid/page/grid-page.component.sass'],
  providers: GRID_PROVIDERS,
})
export class OverviewComponent extends GridPageComponent {
  protected i18nNamespace():string {
    return 'overviews';
  }

  protected isTurboFrameSidebarEnabled():boolean {
    // TODO: check if any project attributes are enabled for this project
    // if not, don't show the sidebar
    return true;
  }

  protected turboFrameSidebarSrc():string {
    return `${this.pathHelper.staticBase}/projects/${this.currentProject.identifier!}/attributes_sidebar`;
  }

  protected turboFrameSidebarId():string {
    return "project-attributes-sidebar";
  }

  protected gridScopePath():string {
    return this.pathHelper.projectPath(this.currentProject.identifier!);
  }
}
