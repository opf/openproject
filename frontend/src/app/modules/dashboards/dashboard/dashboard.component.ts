import {Component, OnInit} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Title} from '@angular/platform-browser';
import {GridInitializationService} from "core-app/modules/grids/grid/initialization.service";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {StateService} from '@uirouter/core';

@Component({
  selector: 'dashboard',
  templateUrl: './dashboard.component.html',
})
export class DashboardComponent implements OnInit {
  public text = { title: this.i18n.t('js.dashboards.label'),
                  html_title: this.i18n.t('js.dashboards.label') };

  constructor(readonly gridInitialization:GridInitializationService,
              readonly pathHelper:PathHelperService,
              readonly halResourceService:HalResourceService,
              readonly state:StateService,
              readonly i18n:I18nService,
              readonly title:Title) {}

  public grid:GridResource;

  ngOnInit() {
    const projectIdentifier = this.state.params['projectPath'];

    this
      .gridInitialization
      .initialize(this.pathHelper.projectDashboardsPath(projectIdentifier))
      .then((grid) => {
        this.grid = grid;
      });

    this.setHtmlTitle();
  }

  private setHtmlTitle() {
    this.title.setTitle(this.text.html_title);
  }
}
