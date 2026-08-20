//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { CardHighlightingMode } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting-mode.const';
import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

export type BoardType = 'free' | 'action';

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

  public get projectId() {
    return this.grid.projectId;
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

  public get actionAttribute():string | undefined {
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
    this.grid.widgets = this.grid.widgets.filter((el) => el.options.queryId !== widget.options.queryId);
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
    this.grid.widgets = this.grid.widgets.sort((a, b) => a.startColumn - b.startColumn);
  }

  public showStatusButton() {
    return this.actionAttribute !== 'status';
  }
}
