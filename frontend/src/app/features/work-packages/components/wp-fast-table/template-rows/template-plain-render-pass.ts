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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { PlainRenderPass } from '../builders/modes/plain/plain-render-pass';
import { RenderedOccurrence, wpOccurrenceKey } from '../rendered-occurrence-ledger';
import { TemplateRow, TemplateRowView } from './template-row';
import { rowHighlightClasses } from '../builders/highlighting/row-highlight-render-pass';
import { WorkPackageViewHighlightingService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';

/**
 * Produces the rows of a flat table as data for the row template instead
 * of DOM. Row highlighting is bound by the template; the other secondary
 * passes (timeline, relations, drag handles) are not supported yet, so
 * the pass only runs for tables that need none of them.
 */
export class TemplatePlainRenderPass extends PlainRenderPass {
  public readonly templateRows:TemplateRow[] = [];

  public readonly view:TemplateRowView = {
    columns: this.rowBuilder.renderedColumns,
    rowHeader: this.rowBuilder.rowHeaderColumn,
    rowClasses: (workPackage) => rowHighlightClasses(this.injector.get(WorkPackageViewHighlightingService), workPackage),
    buildCell: (workPackage, column) => this.rowBuilder.buildCell(workPackage, column),
    isEditing: (workPackage, column, cell) => this.isEditing(workPackage, column, cell),
  };

  public override render():this {
    this.prepare();
    this.doRender();
    return this;
  }

  public override refresh(occurrence:RenderedOccurrence, workPackage:WorkPackageResource):HTMLTableRowElement|null {
    return this.workPackageTable.templateRows?.refreshRow(occurrence.key, workPackage) ?? null;
  }

  protected override doRender():void {
    this.workPackageTable.originalRows.forEach((id) => {
      const workPackage = this.workPackageTable.originalRowIndex[id].object;
      const key = wpOccurrenceKey(id);
      this.templateRows.push({ key, workPackage, revision: 0 });
      this.draft.append({
        key,
        kind: 'workPackage',
        classIdentifier: this.rowBuilder.classIdentifier(workPackage),
        additionalClasses: [],
        workPackage,
        workPackageId: id,
        renderType: 'primary',
        hidden: false,
        level: 1,
        element: null,
      });
    });
  }

  private isEditing(workPackage:WorkPackageResource, column:QueryColumn, cell:HTMLTableCellElement):boolean {
    const field = this.workPackageTable.editing.forms[workPackage.id!]?.activeFields[column.id];
    return field?.element !== undefined && cell.contains(field.element);
  }
}
