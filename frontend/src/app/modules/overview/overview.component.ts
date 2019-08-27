import {Component, OnInit} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Title} from '@angular/platform-browser';
import {GridInitializationService} from "core-app/modules/grids/grid/initialization.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {GridPageComponent} from "core-app/modules/grids/grid/page/grid-page.component";

@Component({
  selector: 'overview',
  templateUrl: '../grids/grid/page/grid-page.component.html',
})
export class OverviewComponent extends GridPageComponent {
  constructor(readonly gridInitialization:GridInitializationService,
              readonly pathHelper:PathHelperService,
              readonly currentProject:CurrentProjectService,
              readonly i18n:I18nService,
              readonly title:Title) {
    super(gridInitialization, pathHelper, i18n, title);
  }

  protected i18nNamespace():string {
    return 'overviews';
  }

  protected gridScopePath():string {
    return this.pathHelper.projectPath(this.currentProject.identifier!);
  }
}
