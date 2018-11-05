import {Component, OnInit, AfterViewInit} from "@angular/core";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";

@Component({
  templateUrl: './grid.component.html',
  selector: 'grid'
})
export class GridComponent implements OnInit, AfterViewInit {
  public gridItems = [];

  constructor(readonly gridDm:GridDmService) {}

  ngOnInit() {
    this.gridDm.load().then((grid:GridResource) => {

      console.log('done');
    });
  }

  //public get actions() {
  //  return _.flatten(this.hookService.call('customActions', this.workPackage));
  //}

  ngAfterViewInit() {
    setTimeout(() => {
      this.actions.forEach((action:CustomActionResource) => {
        this.createComponent(action);
      });
    });
  }

  createComponent(spec:any) {
    const factory = this.resolver.resolveComponentFactory(spec.component);

    this.componentRef = this.actionContainer.createComponent(factory);

    this.componentRef.instance.workPackage = this.workPackage;
    this.componentRef.instance.action = spec.action;
  }
}
