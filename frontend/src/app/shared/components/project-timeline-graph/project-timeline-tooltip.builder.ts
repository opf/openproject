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

import { Injectable, inject } from '@angular/core';
import { diamondIconData, opGateIconData, opPhaseIconData, zapIconData } from '@openproject/octicons-angular';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { octiconElement } from 'core-app/shared/helpers/op-icon-builder';
import { html, nothing } from 'lit-html';
import type { TemplateResult } from 'lit-html';
import { classMap } from 'lit-html/directives/class-map.js';
import { styleMap } from 'lit-html/directives/style-map.js';
import type { ProjectTimelineItem } from './project-timeline-item.builder';
import type { CaretPlacement } from './project-timeline-tooltip-caret';

export interface TooltipView {
  anchor:HTMLElement | null;
  content:HTMLElement | string | null;
  caret:CaretPlacement | null;
}

@Injectable()
export class ProjectTimelineTooltipBuilder {
  private readonly i18n = inject(I18nService);
  private readonly timezone = inject(TimezoneService);

  popoverTemplate({ anchor, content, caret }:TooltipView):TemplateResult {
    return html`
      <anchored-position
        class="op-project-timeline-graph--tooltip"
        popover="manual"
        side="outside-top"
        align="center"
        anchor-offset="spacious"
        .anchorElement=${anchor}>
        <div
          class=${classMap({
            'Popover-message': true,
            'Popover-message--bottom': caret?.side === 'bottom',
            'Popover-message--left': caret?.side === 'left',
            'Popover-message--right': caret?.side === 'right',
          })}
          style=${styleMap({ '--op-timeline-tooltip-caret-offset': caret ? `${caret.offset}px` : null })}>
          ${content ?? nothing}
        </div>
      </anchored-position>
    `;
  }

  tooltipTemplate(item:ProjectTimelineItem):HTMLElement | string {
    if (item.type === 'background') return '';

    const name = document.createElement('div');
    name.className = 'op-timeline-tooltip--name';

    const wrapper = document.createElement('div');
    wrapper.className = 'op-timeline-tooltip';

    if (item.isCluster === true && item.items?.length) {
      const { dateStr, titleText } = this.tooltipClusterData(item.items);
      name.textContent = titleText;
      wrapper.append(this.buildClusterMetaRow(dateStr), name);
    } else {
      name.textContent = item.title;
      wrapper.append(this.buildTooltipMetaRow(item), name);
    }

    return wrapper;
  }

  buildClusterMetaRow(dateStr:string):HTMLElement {
    const typeSpan = document.createElement('span');
    typeSpan.className = 'op-timeline-tooltip--type';
    typeSpan.append(this.i18n.t('js.grid.widgets.project_timeline.tooltip_type_gate'));

    const metaRow = document.createElement('div');
    metaRow.className = 'op-timeline-tooltip--meta-row';
    metaRow.append(`${dateStr} `, octiconElement(opGateIconData, 'small', 'octicon'), typeSpan);
    return metaRow;
  }

  buildTooltipMetaRow(item:ProjectTimelineItem):HTMLElement {
    const typeSpan = document.createElement('span');
    typeSpan.className = 'op-timeline-tooltip--type';
    typeSpan.append(this.tooltipTypeLabel(item.itemType));

    const metaRow = document.createElement('div');
    metaRow.className = 'op-timeline-tooltip--meta-row';
    metaRow.append(`${this.tooltipDateStr(item)} `, this.tooltipIcon(item), typeSpan);
    return metaRow;
  }

  tooltipDateStr(item:ProjectTimelineItem):string {
    const fmt = (d:Date | string) => this.timezone.formattedDate(d as string);
    const isSingleDate = item.itemType === 'milestone' || item.itemType === 'gate';
    if (isSingleDate) return fmt(item.start);
    return item.originalEnd
      ? fmt(item.originalEnd)
      : `${fmt(item.start)} – ${fmt(item.end!)}`;
  }

  tooltipTypeLabel(itemType:ProjectTimelineItem['itemType']):string {
    if (itemType === 'milestone') return this.i18n.t('js.grid.widgets.project_timeline.tooltip_type_milestone');
    if (itemType === 'gate') return this.i18n.t('js.grid.widgets.project_timeline.tooltip_type_gate');
    if (itemType === 'sprint') return this.i18n.t('js.grid.widgets.project_timeline.tooltip_type_sprint');
    return this.i18n.t('js.grid.widgets.project_timeline.tooltip_type_phase');
  }

  tooltipIcon(item:ProjectTimelineItem):HTMLElement {
    if (item.itemType === 'milestone') {
      return octiconElement(diamondIconData, 'xsmall', `octicon __hl_inline_type_${item.typeId!}`);
    }
    if (item.itemType === 'sprint') {
      return octiconElement(zapIconData, 'small', 'octicon op-timeline-sprint-icon');
    }
    const iconData = item.itemType === 'gate' ? opGateIconData : opPhaseIconData;
    return octiconElement(iconData, 'small', `octicon __hl_inline_project_phase_definition_${item.definitionId!}`);
  }

  tooltipClusterData(items:ProjectTimelineItem[]):{dateStr:string; titleText:string} {
    const sorted = items.slice().sort((a, b) => new Date(a.start).getTime() - new Date(b.start).getTime());
    const minDate = sorted[0].start;
    const maxDate = sorted[sorted.length - 1].start;
    const dateStr = minDate === maxDate
      ? this.timezone.formattedDate(minDate as string)
      : `${this.timezone.formattedDate(minDate as string)} – ${this.timezone.formattedDate(maxDate as string)}`;

    return { dateStr, titleText: items.map((i) => i.title).join(', ') };
  }

}
