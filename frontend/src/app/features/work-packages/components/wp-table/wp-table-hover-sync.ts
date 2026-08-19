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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

const cssClassRowHovered = 'row-hovered';

export class WpTableHoverSync {
  private lastHoveredElement:Element | null = null;

  private eventListener = (evt:MouseEvent) => {
    const target = evt.target as HTMLElement|null;
    if (target && target !== this.lastHoveredElement) {
      this.handleHover(target);
    }
    this.lastHoveredElement = target;
  };

  constructor(private tableAndTimeline:HTMLElement) {
  }

  activate() {
    window.addEventListener('mousemove', this.eventListener, { passive: true });
  }

  deactivate() {
    window.removeEventListener('mousemove', this.eventListener);
    this.removeAllHoverClasses();
  }

  private locateHoveredTableRow(child:HTMLElement):HTMLTableRowElement | null {
    return child.closest('tr');
  }

  private locateHoveredTimelineRow(child:HTMLElement):HTMLElement | null {
    return child.closest('div.wp-timeline-cell');
  }

  private handleHover(element:HTMLElement) {
    const parentTableRow = this.locateHoveredTableRow(element);
    const parentTimelineRow = this.locateHoveredTimelineRow(element);

    // remove all hover classes if cursor does not hover a row
    if (parentTableRow === null && parentTimelineRow === null) {
      this.removeAllHoverClasses();
      return;
    }

    this.removeOldAndAddNewHoverClass(parentTableRow, parentTimelineRow);
  }

  private extractWorkPackageId(row:Element):number {
    return parseInt(row.getAttribute('data-work-package-id')!);
  }

  private removeOldAndAddNewHoverClass(parentTableRow:Element | null, parentTimelineRow:Element | null) {
    const hovered = parentTableRow !== null ? parentTableRow : parentTimelineRow;
    const wpId = this.extractWorkPackageId(hovered!);

    const tableRow = this.tableAndTimeline.querySelector(`tr.wp-row-${wpId}`);
    const timelineRow = this.tableAndTimeline.querySelector(`div.wp-row-${wpId}`)
      ? this.tableAndTimeline.querySelector(`div.wp-row-${wpId}`)
      : this.tableAndTimeline.querySelector(`div.wp-ancestor-row-${wpId}`);

    requestAnimationFrame(() => {
      this.removeAllHoverClasses();
      timelineRow?.classList.add(cssClassRowHovered);
      tableRow?.classList.add(cssClassRowHovered);
    });
  }

  private removeAllHoverClasses() {
    this.tableAndTimeline
      .querySelectorAll(`.${cssClassRowHovered}`)
      .forEach((elem) => elem.classList.remove(cssClassRowHovered));
  }
}
