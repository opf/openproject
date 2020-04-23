import { ChangeDetectorRef, OnDestroy, OnInit, Renderer2, Directive } from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Title} from '@angular/platform-browser';
import {GridInitializationService} from "core-app/modules/grids/grid/initialization.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {GridAddWidgetService} from "core-app/modules/grids/grid/add-widget.service";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";

@Directive()
export abstract class GridPageComponent implements OnInit, OnDestroy {
  public text = { title: this.i18n.t(`js.${this.i18nNamespace()}.label`),
                  html_title: this.i18n.t(`js.${this.i18nNamespace()}.label`) };

  constructor(readonly gridInitialization:GridInitializationService,
              // not used in the base class but will be used throughout the subclasses
              readonly pathHelper:PathHelperService,
              readonly currentProject:CurrentProjectService,
              readonly i18n:I18nService,
              readonly cdRef:ChangeDetectorRef,
              readonly title:Title,
              readonly addWidget:GridAddWidgetService,
              readonly renderer:Renderer2,
              readonly areas:GridAreaService) {}

  public grid:GridResource;

  ngOnInit() {
    this.renderer.addClass(document.body, 'widget-grid-layout');
    this
      .gridInitialization
      .initialize(this.gridScopePath())
      .then((grid) => {
        this.grid = grid;
        this.cdRef.detectChanges();
      });

    this.setHtmlTitle();
  }

  ngOnDestroy():void {
    this.renderer.removeClass(document.body, 'widget-grid-layout');
  }

  private setHtmlTitle() {
    this.title.setTitle(this.text.html_title);
  }

  protected abstract i18nNamespace():string;

  protected abstract gridScopePath():string;
}
