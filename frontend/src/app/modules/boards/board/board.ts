import { GridWidgetResource } from "core-app/modules/hal/resources/grid-widget-resource";
import { GridResource } from "core-app/modules/hal/resources/grid-resource";
import { CardHighlightingMode } from "core-components/wp-fast-table/builders/highlighting/highlighting-mode.const";
import { ApiV3Filter } from "core-components/api/api-v3/api-v3-filter-builder";

export type BoardType = 'free'|'action';

export interface BoardWidgetOption {
  queryId:string;
  filters:ApiV3Filter[];
}

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

  public set highlightingMode(val:CardHighlightingMode) {
    this.grid.options.highlightingMode = val;
  }

  public get highlightingMode():CardHighlightingMode {
    return (this.grid.options.highlightingMode || 'none') as CardHighlightingMode;
  }

  public set name(name:string) {
    this.grid.name = name;
  }

  public addQuery(widget:GridWidgetResource) {
    widget.isNewWidget = true;
    this.grid.widgets.push(widget);
  }

  public removeQuery(widget:GridWidgetResource) {
    this.grid.widgets = this.grid.widgets.filter(el => el.options.queryId !== widget.options.queryId);
  }

  public get queries():GridWidgetResource[] {
    return this.grid.widgets;
  }

  public get createdAt() {
    return this.grid.createdAt;
  }

  public get filters():ApiV3Filter[] {
    return (this.grid.options.filters || []) as ApiV3Filter[];
  }

  public set filters(filters:ApiV3Filter[]) {
    this.grid.options.filters = filters;
  }

  public sortWidgets() {
    this.grid.widgets = this.grid.widgets.sort((a, b) => {
      return a.startColumn - b.startColumn;
    });
  }

  public showStatusButton() {
    return this.actionAttribute !== 'status';
  }
}
