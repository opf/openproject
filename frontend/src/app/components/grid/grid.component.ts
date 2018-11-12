import {Component, OnInit, AfterViewInit, ComponentFactoryResolver, ElementRef, ViewChild, ViewContainerRef,
  ComponentRef,
  OnDestroy} from "@angular/core";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {WidgetWpAssignedComponent} from "core-components/grid/widgets/wp-assigned/wp-assigned.component";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {HookService} from "core-app/modules/plugins/hook-service";
import {debugLog} from "core-app/helpers/debug_output";
import {DomSanitizer} from "@angular/platform-browser";

export interface WidgetRegistration {
  identifier:string;
  // TODO: Find out how to declare component to be of type class
  component:any;
}

@Component({
  templateUrl: './grid.component.html',
  selector: 'grid'
})
export class GridComponent implements OnInit, AfterViewInit, OnDestroy {
  public gridWidgets:ComponentRef<any>[] = [];
  private registeredWidgets:WidgetRegistration[] = [];
  private numColumns:number = 0;
  private numRows:number = 0;

  @ViewChild('gridContent', { read: ViewContainerRef }) gridContent:ViewContainerRef;

  public areaResources = [{component: WidgetWpAssignedComponent}];

  constructor(readonly gridDm:GridDmService,
              readonly resolver:ComponentFactoryResolver,
              readonly Hook:HookService,
              private sanitization:DomSanitizer) {}

  ngOnInit() {
    _.each(this.Hook.call('gridWidgets'), (registration:WidgetRegistration[]) => {
      this.registeredWidgets = this.registeredWidgets.concat(registration);
    });
  }

  ngOnDestroy() {
    this.gridWidgets.forEach((widget) => widget.destroy());
  }

  ngAfterViewInit() {
    this.gridDm.load().then((grid:GridResource) => {
      this.numRows = grid.rowCount;
      this.numColumns = grid.columnCount;

      grid.widgets.forEach((widget) => {
        this.createWidget(widget);
      });
    });
  }

  createWidget(widget:GridWidgetResource) {
    let registration = this.registeredWidgets.find((reg) => reg.identifier === widget.identifier);

    if (!registration) {
      debugLog(`No widget registered with identifier ${widget.identifier}`);

      return;
    }

    const factory = this.resolver.resolveComponentFactory(registration.component);

    let componentRef = this.gridContent.createComponent(factory);
    (componentRef.instance as WidgetWpAssignedComponent).widgetResource = widget;

    this.gridWidgets.push(componentRef);
  }

  public get gridColumnStyle() {
    return this.sanitization.bypassSecurityTrustStyle(`repeat(${this.numColumns}, 1fr)`);
  }

  public get gridRowStyle() {
    return this.sanitization.bypassSecurityTrustStyle(`'repeat(${this.numRows}, 1fr)'`);
  }

  public get gridCellArray() {
    let cells = [];

    for (let i = 1; i <= this.numRows; i++) {
      for (let j = 1; j <= this.numColumns; j++) {
        cells.push([i, j]);
      }
    }

    return cells;
  }
}
