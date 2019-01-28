import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";

export class Board {
  constructor(public grid:GridResource, public name:string) {
  }

  public get id() {
    return this.grid.id;
  }

  public addQuery(widget:GridWidgetResource) {
    this.grid.widgets.push(widget);
  }

  public get queries():number[] {
    return this.grid.widgets.map((w:GridWidgetResource) => w.options.query_id as number);
  }
}
