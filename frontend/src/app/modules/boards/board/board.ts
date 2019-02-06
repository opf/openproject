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

  public get queries():GridWidgetResource[] {
    return this.grid.widgets;
  }

  public get createdAt() {
    return this.grid.createdAt;
  }
}
