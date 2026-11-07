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

export function assertActions(root:HTMLElement, rowCount:number, templates:boolean):void {
  const rows = root.querySelectorAll<HTMLTableRowElement>('.work-package--results-tbody > tr');
  if (rows.length !== rowCount) throw new Error('Incorrect action row count');
  const tooltips = root.querySelectorAll<HTMLElement>('tool-tip');
  if (tooltips.length !== rowCount * 2) throw new Error(`Expected two tooltips per row, got ${tooltips.length}`);
  const tooltipIds = new Set<string>();
  const byControl = new Map<string, HTMLElement[]>();
  tooltips.forEach((tip) => {
    const owner = tip.getAttribute('for') ?? '';
    const owned = byControl.get(owner) ?? [];
    owned.push(tip);
    byControl.set(owner, owned);
  });
  rows.forEach((row, index) => {
    const id = String(index + 1);
    const cell = row.querySelector('.wp-table--context-menu-td');
    const details = cell?.querySelector<HTMLAnchorElement>('a.wp-table--details-link');
    const context = cell?.querySelector<HTMLElement>(templates ? 'button.wp-table-context-menu-link' : 'a.wp-table-context-menu-link');
    if (!details || !context || row.cells.length !== 3) throw new Error(`Missing production actions for ${id}`);
    if (details.getAttribute('href') !== `/details/${id}/overview`
      || details.dataset.workPackageId !== id || details.dataset.wpState !== 'split') {
      throw new Error(`Incorrect details URL or identity for ${id}`);
    }
    if (!templates && context.getAttribute('href') !== '#') throw new Error('Incorrect context action URL');
    for (const [control, label] of [[details, 'js.button_open_details'], [context, 'js.label_open_context_menu']] as const) {
      const owned = byControl.get(control.id) ?? [];
      if (!control.id || owned.length !== 1) throw new Error('Incorrect tooltip ownership');
      const tip = owned[0];
      if (!tip.id || tooltipIds.has(tip.id) || tip.textContent?.trim() !== label
        || !control.getAttribute('aria-labelledby')?.split(/\s+/).includes(tip.id)
        || !(tip instanceof customElements.get('tool-tip')!)) {
        throw new Error('Incorrect production tooltip label or identity');
      }
      tooltipIds.add(tip.id);
    }
  });
}
