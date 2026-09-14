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
import { GridArea } from 'core-app/shared/components/grids/areas/grid-area';

export class GridWidgetArea extends GridArea {
  public widget:GridWidgetResource;

  constructor(widget:GridWidgetResource) {
    super(widget.startRow,
      widget.endRow,
      widget.startColumn,
      widget.endColumn);

    this.widget = widget;
  }

  public reset() {
    this.startRow = this.widget.startRow;
    this.endRow = this.widget.endRow;
    this.startColumn = this.widget.startColumn;
    this.endColumn = this.widget.endColumn;
  }

  public moveRight() {
    this.startColumn++;
    this.endColumn++;
  }

  public moveLeft() {
    this.startColumn--;
    this.endColumn--;
  }

  public growColumn() {
    this.endColumn++;
  }

  public overlaps(otherArea:GridWidgetArea) {
    return this.rowOverlaps(otherArea)
           && this.columnOverlaps(otherArea);
  }

  public rowOverlaps(otherArea:GridWidgetArea) {
    return this.startRow < otherArea.endRow
           && this.endRow >= otherArea.endRow
           || this.startRow <= otherArea.startRow
           && this.endRow > otherArea.startRow
           || this.startRow > otherArea.startRow
           && this.endRow < otherArea.endRow;
  }

  public columnOverlaps(otherArea:GridWidgetArea) {
    return this.startColumn < otherArea.endColumn
           && this.endColumn >= otherArea.endColumn
           || this.startColumn <= otherArea.startColumn
           && this.endColumn > otherArea.startColumn
           || this.startColumn > otherArea.startColumn
           && this.endColumn < otherArea.endColumn;
  }

  public startColumnOverlaps(otherArea:GridWidgetArea) {
    return this.startColumn < otherArea.startColumn
           && this.endColumn > otherArea.startColumn
           && this.rowOverlaps(otherArea);
  }

  public get unchangedSize() {
    return this.startColumn === this.widget.startColumn
           && this.endColumn === this.widget.endColumn
           && this.startRow === this.widget.startRow
           && this.endRow === this.widget.endRow;
  }

  public writeAreaChangeToWidget() {
    this.widget.startRow = this.startRow;
    this.widget.endRow = this.endRow;
    this.widget.startColumn = this.startColumn;
    this.widget.endColumn = this.endColumn;
  }

  public copyDimensionsTo(sink:GridWidgetArea) {
    sink.startRow = this.startRow;
    sink.startColumn = this.startColumn;
    sink.endRow = this.endRow;
    sink.endColumn = this.endColumn;
  }
}
