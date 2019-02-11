import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";

export type BoardDisplayMode = 'table'|'cards';

export class Board {
  constructor(public grid:GridResource) {
  }

  public get id() {
    return this.grid.id;
  }

  public get name() {
    return this.grid.name;
  }

  public get isEditable() {
    return !!this.grid.updateImmediately;
  }

  public get displayMode():BoardDisplayMode {
    const mode = this.grid.options.display_mode;
    return (mode === 'table') ? 'table' : 'cards';
  }

  public set displayMode(value:BoardDisplayMode) {
    this.grid.options.display_mode = value;
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
