import { ChangeDetectionStrategy, Component } from '@angular/core';
import { GridPageComponent } from 'core-app/shared/components/grids/grid/page/grid-page.component';
import { GRID_PROVIDERS } from 'core-app/shared/components/grids/grid/grid.component';

@Component({
  selector: 'overview',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: '../../shared/components/grids/grid/page/grid-page.component.html',
  styleUrls: ['../../shared/components/grids/grid/page/grid-page.component.sass'],
  providers: GRID_PROVIDERS,
})
export class OverviewComponent extends GridPageComponent {
  showToolbar = false;

  protected i18nNamespace():string {
    return 'overviews';
  }

  protected isTurboFrameSidebarEnabled():boolean {
    const sidebarEnabledTag:HTMLMetaElement|null = document.querySelector('meta[name="sidebar_enabled"]');
    return sidebarEnabledTag?.dataset.enabled === 'true';
  }

  protected turboFrameSidebarSrc():string {
    return `${this.pathHelper.staticBase}/projects/${this.currentProject.identifier ?? ''}/project_custom_fields_sidebar`;
  }

  protected turboFrameSidebarId():string {
    return 'project-custom-fields-sidebar';
  }

  protected gridScopePath():string {
    return this.pathHelper.projectPath(this.currentProject.identifier ?? '');
  }
}
