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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import type { TextCellPresentation } from './text-cell-presentation';
import type { IdCellPresentation } from './id-cell-presenter';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { OccurrenceKey, RenderedOccurrence } from '../rendered-occurrence-ledger';
import { OpTableAction } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';

interface TemplateRowIdentity {
  readonly key:OccurrenceKey;
  readonly classIdentifier:string;
  readonly additionalClasses:readonly string[];
}

export interface TemplateWorkPackageRow extends TemplateRowIdentity {
  readonly kind:'workPackage';
  readonly workPackage:WorkPackageResource;
  readonly level:number;
  readonly relation?:RenderedOccurrence['relation'];
  /** Bumped on every refresh, since refreshed resources may be the same mutated instance. */
  readonly revision:number;
}

export interface TemplateGroupHeader extends TemplateRowIdentity {
  readonly kind:'groupHeader';
  readonly index:number;
  readonly identifier:string;
  readonly name:string;
  readonly count:number;
  readonly collapsed:boolean;
  readonly expandLabel:string;
  readonly collapseLabel:string;
  readonly leadingIcon:HTMLElement|null;
}

interface TemplateGroupSums extends TemplateRowIdentity {
  readonly kind:'sums';
  readonly cells:readonly TemplateSumCell[];
}

export interface TemplateSumCell {
  readonly columnId:string;
  readonly navigable:boolean;
  readonly describedBy:string|null;
  readonly content:HTMLElement;
}

export type TemplateRow = TemplateWorkPackageRow|TemplateGroupHeader|TemplateGroupSums;

export interface TemplateRowView {
  readonly columns:readonly QueryColumn[];
  readonly rowHeader:'subject'|'id'|null;
  rowClasses(workPackage:WorkPackageResource):readonly string[];
  /** The actions of the trailing cell, or null when that cell is not an actions cell. */
  actions(workPackage:WorkPackageResource):readonly OpTableAction[]|null;
  readonly contextMenuLabel:string;
  /** Whether the row offers a drag handle, or null when the table has no drag and drop. */
  canDrag(workPackage:WorkPackageResource):boolean|null;
  /** An empty drag and drop table renders a placeholder row as its drop target. */
  readonly placeholder:boolean;
  idCell(workPackage:WorkPackageResource):IdCellPresentation;
  textCell(row:TemplateWorkPackageRow, column:QueryColumn):TextCellPresentation|null;
  buildCell(row:TemplateWorkPackageRow, column:QueryColumn):HTMLTableCellElement|null;
  isEditing(workPackage:WorkPackageResource, column:QueryColumn, cell:HTMLTableCellElement):boolean;
}

/** Renders template rows synchronously into the table's results body. */
export interface TemplateRowsHost {
  renderRows(rows:readonly TemplateRow[], view:TemplateRowView):void;
}
