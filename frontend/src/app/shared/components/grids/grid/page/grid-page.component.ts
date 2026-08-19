import { ChangeDetectorRef, Directive, inject, OnDestroy, OnInit, Renderer2 } from '@angular/core';
import { GridInitializationService } from 'core-app/shared/components/grids/grid/initialization.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { GridAddWidgetService } from 'core-app/shared/components/grids/grid/add-widget.service';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

@Directive()
export abstract class GridPageComponent implements OnInit, OnDestroy {
  readonly gridInitialization = inject(GridInitializationService);
  readonly pathHelper = inject(PathHelperService);
  readonly currentProject = inject(CurrentProjectService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly addWidget = inject(GridAddWidgetService);
  readonly renderer = inject(Renderer2);
  readonly areas = inject(GridAreaService);
  readonly configurationService = inject(ConfigurationService);

  public grid:GridResource;

  ngOnInit() {
    this.renderer.addClass(document.body, 'widget-grid-layout');
    this
      .gridInitialization
      .initialize(this.gridScopePath())
      .subscribe((grid) => {
        this.grid = grid;
        this.cdRef.detectChanges();
      });
  }

  ngOnDestroy():void {
    this.renderer.removeClass(document.body, 'widget-grid-layout');
  }

  protected abstract gridScopePath():string;
}
