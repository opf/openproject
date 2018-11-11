import {Component, OnInit, AfterViewInit, ComponentFactoryResolver, ElementRef, ViewChild, ViewContainerRef,
  ComponentRef,
  OnDestroy} from "@angular/core";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {WidgetWpAssignedComponent} from "core-components/grid/widgets/wp-assigned/wp-assigned.component";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {HookService} from "core-app/modules/plugins/hook-service";
import {debugLog} from "core-app/helpers/debug_output";

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

  @ViewChild('gridContainer', { read: ViewContainerRef }) gridContainer:ViewContainerRef;

  public areaResources = [{component: WidgetWpAssignedComponent}];

  constructor(readonly gridDm:GridDmService,
              readonly resolver:ComponentFactoryResolver,
              readonly Hook:HookService) {}

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

    let componentRef = this.gridContainer.createComponent(factory);
    (componentRef.instance as WidgetWpAssignedComponent).widgetResource = widget;

    this.gridWidgets.push(componentRef);
  }
}
