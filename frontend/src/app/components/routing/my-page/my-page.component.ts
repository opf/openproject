import {Component, OnInit} from "@angular/core";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Title} from '@angular/platform-browser';
import {GridInitializationService} from "core-app/modules/grids/grid/initialization.service";

@Component({
  templateUrl: './my-page.component.html'
})
export class MyPageComponent implements OnInit {
  public text = { title: this.i18n.t('js.label_my_page'),
                  html_title: this.i18n.t('js.label_my_page') };

  constructor(readonly gridInitialization:GridInitializationService,
              readonly pathHelper:PathHelperService,
              readonly halResourceService:HalResourceService,
              readonly i18n:I18nService,
              readonly title:Title) {}

  public grid:GridResource;

  ngOnInit() {
    this
      .gridInitialization
      .initialize(this.pathHelper.myPagePath())
      .then((grid) => {
        this.grid = grid;
      });

    this.setHtmlTitle();
  }

  private setHtmlTitle() {
    this.title.setTitle(this.text.html_title);
  }
}
