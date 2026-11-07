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
import type { RenderDraft } from '../rendered-occurrence-ledger';

/** The fast table's side of template rendering: what is rendered, and the element of each row. */
export class TemplateRowsController {
  private rows:readonly TemplateRow[] = [];

  private view:TemplateRowView|null = null;

  constructor(
    private readonly host:TemplateRowsHost,
    private readonly tbody:HTMLTableSectionElement,
  ) {}

  public commit(draft:RenderDraft, rows:readonly TemplateRow[], view:TemplateRowView):void {
    this.render(rows, view);
    const elements = new Map(
      Array.from(this.tbody.querySelectorAll<HTMLTableRowElement>(':scope > tr[data-occurrence-key]'), (row) => [row.dataset.occurrenceKey!, row]),
    );
    draft.occurrences.forEach((occurrence) => {
      occurrence.element = elements.get(occurrence.key) ?? null;
    });
  }

  /** Whether the row is rendered by the template rather than by an imperative pass. */
  public owns(row:HTMLTableRowElement):boolean {
    return this.rows.some(({ key }) => key === row.dataset.occurrenceKey);
  }

  public snapshot():readonly OccurrenceKey[] {
    return this.rows.map(({ key }) => key);
  }

  public restore(order:readonly OccurrenceKey[]):void {
    const current = new Map(this.rows.map((row) => [row.key, row]));
    if (order.length !== current.size || order.some((key) => !current.has(key))) return;
    this.render(order.map((key) => current.get(key)!), this.view);
  }

  /** Moves a row next to another, as a drop shows the new order before it is saved. */
  public move(sourceKey:OccurrenceKey, targetKey:OccurrenceKey|null, before:boolean):void {
    const source = this.rows.find(({ key }) => key === sourceKey);
    if (!source) return;

    const rest = this.rows.filter((row) => row !== source);
    const targetIndex = rest.findIndex(({ key }) => key === targetKey);
    const at = targetIndex === -1 ? rest.length : targetIndex + (before ? 0 : 1);
    this.render([...rest.slice(0, at), source, ...rest.slice(at)], this.view);
  }

  public clear():void {
    if (this.rows.length > 0) this.render([], this.view);
  }

  public refreshRow(key:OccurrenceKey, workPackage:WorkPackageResource):HTMLTableRowElement|null {
    if (!this.rows.some((row) => row.kind === 'workPackage' && row.key === key)) return null;

    this.render(
      this.rows.map((row) => (row.kind === 'workPackage' && row.key === key ? { ...row, workPackage, revision: row.revision + 1 } : row)),
      this.view,
    );
    return this.elementOf(key);
  }

  public refreshWorkPackages(updates:ReadonlyMap<string, WorkPackageResource>):Map<OccurrenceKey, HTMLTableRowElement> {
    const changed = new Set<OccurrenceKey>();
    const rows = this.rows.map((row) => {
      const workPackage = row.kind === 'workPackage' ? updates.get(row.workPackage.id!) : undefined;
      if (!workPackage || row.kind !== 'workPackage') return row;
      changed.add(row.key);
      return { ...row, workPackage, revision: row.revision + 1 };
    });
    if (changed.size === 0) return new Map();
    this.render(rows, this.view);
    return new Map(Array.from(this.tbody.rows)
      .filter((element) => changed.has(element.dataset.occurrenceKey!))
      .map((element) => [element.dataset.occurrenceKey!, element]));
  }

  public updateGroupHeaders(collapsed:ReadonlyMap<OccurrenceKey, boolean>):void {
    if (collapsed.size === 0) return;
    this.render(this.rows.map((row) => (row.kind === 'groupHeader' && collapsed.has(row.key)
      ? { ...row, collapsed: collapsed.get(row.key)! }
      : row)), this.view);
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
