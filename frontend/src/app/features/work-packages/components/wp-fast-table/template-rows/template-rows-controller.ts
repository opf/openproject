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
import { OccurrenceKey } from '../rendered-occurrence-ledger';
import { TemplateRow, TemplateRowsHost, TemplateRowView } from './template-row';
import type { TemplatePlainRenderPass } from './template-plain-render-pass';

/** The fast table's side of template rendering: what is rendered, and the element of each row. */
export class TemplateRowsController {
  private rows:readonly TemplateRow[] = [];

  private view:TemplateRowView|null = null;

  constructor(
    private readonly host:TemplateRowsHost,
    private readonly tbody:HTMLTableSectionElement,
  ) {}

  public commit(pass:TemplatePlainRenderPass):void {
    this.render(pass.templateRows, pass.view);
    pass.draft.occurrences.forEach((occurrence) => {
      occurrence.element = this.elementOf(occurrence.key);
    });
  }

  public clear():void {
    if (this.rows.length > 0) this.render([], this.view);
  }

  public refreshRow(key:OccurrenceKey, workPackage:WorkPackageResource):HTMLTableRowElement|null {
    if (!this.rows.some((row) => row.key === key)) return null;

    this.render(
      this.rows.map((row) => (row.key === key ? { key, workPackage, revision: row.revision + 1 } : row)),
      this.view,
    );
    return this.elementOf(key);
  }

  private render(rows:readonly TemplateRow[], view:TemplateRowView|null):void {
    this.rows = rows;
    this.view = view;
    if (view) this.host.renderRows(rows, view);
  }

  private elementOf(key:OccurrenceKey):HTMLTableRowElement|null {
    return this.tbody.querySelector<HTMLTableRowElement>(`:scope > tr[data-occurrence-key="${CSS.escape(key)}"]`);
  }
}
