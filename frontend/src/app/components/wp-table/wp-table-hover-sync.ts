// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

const cssClassRowHovered = 'row-hovered';

export class WpTableHoverSync {

  private lastHoveredElement:Element | null = null;

  private eventListener = (evt:MouseEvent) => {
    const target = evt.target as Element|null;
    if (target && target !== this.lastHoveredElement) {
      this.handleHover(target);
    }
    this.lastHoveredElement = target;
  }

  constructor(private tableAndTimeline:JQuery) {
  }

  activate() {
    window.addEventListener('mousemove', this.eventListener, { passive: true });
  }

  deactivate() {
    window.removeEventListener('mousemove', this.eventListener);
    this.removeAllHoverClasses();
  }

  private locateHoveredTableRow(child:JQuery):Element | null {
    const parent = child.closest('tr');
    if (parent.length === 0) {
      return null;
    }
    return parent[0];
  }

  private locateHoveredTimelineRow(child:JQuery):Element | null {
    const parent = child.closest('div.wp-timeline-cell');
    if (parent.length === 0) {
      return null;
    }
    return parent[0];
  }

  private handleHover(element:Element) {
    const $element = jQuery(element) as JQuery;
    const parentTableRow = this.locateHoveredTableRow($element);
    const parentTimelineRow = this.locateHoveredTimelineRow($element);

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

    const tableRow:JQuery = this.tableAndTimeline.find('tr.wp-row-' + wpId).first();
    const timelineRow:JQuery = this.tableAndTimeline.find('div.wp-row-' + wpId).first();

    requestAnimationFrame(() => {
      this.removeAllHoverClasses();
      timelineRow.addClass(cssClassRowHovered);
      tableRow.addClass(cssClassRowHovered);
    });
  }

  private removeAllHoverClasses() {
    this.tableAndTimeline
      .find(`.${cssClassRowHovered}`)
      .removeClass(cssClassRowHovered);
  }
}
