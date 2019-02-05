import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";

export class Board {
  constructor(public grid:GridResource) {
  }

  public get id() {
    return this.grid.id;
  }

  public get name() {
    return this.grid.name;
  }

  public set name(name:string) {
    this.grid.name = name;
  }

  public addQuery(widget:GridWidgetResource) {
    this.grid.widgets.push(widget);
  }

  public get queries():number[] {
    return this.grid.widgets.map((w:GridWidgetResource) => w.options.query_id as number);
  }
}
