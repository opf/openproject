import {OnInit} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Title} from '@angular/platform-browser';
import {GridInitializationService} from "core-app/modules/grids/grid/initialization.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";

export abstract class GridPageComponent implements OnInit {
  public text = { title: this.i18n.t(`js.${this.i18nNamespace()}.label`),
                  html_title: this.i18n.t(`js.${this.i18nNamespace()}.label`) };

  protected constructor(readonly gridInitialization:GridInitializationService,
                        readonly pathHelper:PathHelperService,
                        readonly i18n:I18nService,
                        readonly title:Title) {}

  public grid:GridResource;

  ngOnInit() {
    this
      .gridInitialization
      .initialize(this.gridScopePath())
      .then((grid) => {
        this.grid = grid;
      });

    this.setHtmlTitle();
  }

  private setHtmlTitle() {
    this.title.setTitle(this.text.html_title);
  }

  protected abstract i18nNamespace():string;

  protected abstract gridScopePath():string;
}
