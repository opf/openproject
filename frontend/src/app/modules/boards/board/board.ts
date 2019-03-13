import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {CardHighlightingMode} from "core-components/wp-fast-table/builders/highlighting/highlighting-mode.const";

export type BoardDisplayMode = 'table'|'cards';
export type BoardType = 'free'|'action';

export class Board {
  constructor(public grid:GridResource) {
  }

  public get id() {
    return this.grid.id;
  }

  public get name() {
    return this.grid.name;
  }

  public get editable() {
    return !!this.grid.updateImmediately;
  }

  public get isFree() {
    return !this.isAction;
  }

  public get isAction() {
    return this.grid.options.type === 'action';
  }

  public get actionAttribute():string|undefined {
    if (this.isFree) {
      return undefined;
    }

    return this.grid.options.attribute as string;
  }

  public get displayMode():BoardDisplayMode {
    return 'cards';
  }

  public set highlightingMode(val:CardHighlightingMode) {
    this.grid.options.highlightingMode = val;
  }

  public get highlightingMode():CardHighlightingMode {
    return this.grid.options.highlightingMode || 'none' ;
  }

  public set name(name:string) {
    this.grid.name = name;
  }

  public addQuery(widget:GridWidgetResource) {
    this.grid.widgets.push(widget);
  }

  public removeQuery(widget:GridWidgetResource) {
    this.grid.widgets = this.grid.widgets.filter(el => el.options.query_id !== widget.options.query_id);
  }

  public get queries():GridWidgetResource[] {
    return this.grid.widgets;
  }

  public get createdAt() {
    return this.grid.createdAt;
  }
}
