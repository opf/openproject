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

import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { States } from 'core-app/core/states/states.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

/** Delay before a preview appears so quick pointer passes over rows do not flash cards. */
const SHOW_DELAY = 400;
const PREVIEW_CLASS = 'wp-hover-preview';

/**
 * Shows a small preview card with basic work package information while hovering a row.
 * Uses the work package already loaded by the table, so no additional request is made.
 */
export class HoverPreviewHandler implements TableEventHandler {
  @LazyInject() public states:States;

  @LazyInject() public I18n:I18nService;

  @LazyInject() public timezoneService:TimezoneService;

  private showTimer:number|undefined;

  private hoveredRow:HTMLTableRowElement|null = null;

  private preview:HTMLElement|null = null;

  constructor(public readonly injector:Injector) {
  }

  public get EVENT():EventType[] {
    return ['mouseover', 'mouseout'];
  }

  public get SELECTOR() {
    return `.${tableRowClassName}`;
  }

  public eventScope(view:TableEventComponent) {
    return view.workPackageTable.tbody;
  }

  public handleEvent(_view:TableEventComponent, evt:Event):void {
    if (evt.type === 'mouseover') {
      this.onOver(evt as MouseEvent);
    } else {
      this.onOut(evt as MouseEvent);
    }
  }

  private onOver(evt:MouseEvent):void {
    const row = this.rowFor(evt.target);
    if (!row || row === this.hoveredRow) {
      return;
    }

    this.clearTimer();
    this.removePreview();
    this.hoveredRow = row;
    this.showTimer = window.setTimeout(() => {
      this.showTimer = undefined;
      this.showPreview(row);
    }, SHOW_DELAY);
  }

  private onOut(evt:MouseEvent):void {
    const row = this.rowFor(evt.target);
    if (!row) {
      return;
    }

    const related = evt.relatedTarget as Node|null;
    if (related && (row.contains(related) || this.preview?.contains(related))) {
      return;
    }

    this.clearTimer();
    this.removePreview();
    this.hoveredRow = null;
  }

  private showPreview(row:HTMLTableRowElement):void {
    const workPackageId = row.dataset.workPackageId;
    if (!workPackageId) {
      return;
    }

    const workPackage = this.states.workPackages.get(workPackageId).value as WorkPackageResource|undefined;
    if (!workPackage) {
      return;
    }

    const preview = this.buildPreview(workPackage);
    document.body.appendChild(preview);
    this.preview = preview;
    this.position(preview, row);
  }

  private buildPreview(workPackage:WorkPackageResource):HTMLElement {
    const preview = document.createElement('div');
    preview.className = PREVIEW_CLASS;
    preview.setAttribute('role', 'tooltip');
    Object.assign(preview.style, {
      position: 'fixed',
      zIndex: '1000',
      pointerEvents: 'none',
      maxWidth: '320px',
      padding: '8px 12px',
      fontSize: '12px',
      lineHeight: '1.4',
      borderRadius: '6px',
      border: '1px solid var(--borderColor-default, #d0d7de)',
      background: 'var(--body-background, #ffffff)',
      color: 'var(--body-font-color, #1f2328)',
      boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
    });

    const subject = document.createElement('div');
    subject.className = `${PREVIEW_CLASS}--subject`;
    subject.style.fontWeight = '600';
    subject.style.marginBottom = '6px';
    subject.textContent = workPackage.subjectWithId ? workPackage.subjectWithId() : workPackage.subject;
    preview.appendChild(subject);

    const fields = document.createElement('dl');
    Object.assign(fields.style, {
      display: 'grid',
      gridTemplateColumns: 'auto 1fr',
      gap: '2px 8px',
      margin: '0',
    });
    preview.appendChild(fields);

    this.appendField(fields, 'js.work_packages.properties.assignee', workPackage.assignee?.name);
    this.appendField(fields, 'js.work_packages.properties.workAlternative', workPackage.estimatedTime);
    this.appendField(fields, 'js.work_packages.properties.spentTime', workPackage.spentTime);
    this.appendField(fields, 'js.work_packages.properties.remainingTime', workPackage.remainingTime);

    return preview;
  }

  private appendField(list:HTMLElement, labelKey:string, value:unknown):void {
    const dt = document.createElement('dt');
    dt.textContent = this.I18n.t(labelKey);
    dt.style.color = 'var(--fgColor-muted, #59636e)';

    const dd = document.createElement('dd');
    dd.style.margin = '0';
    dd.textContent = this.formatValue(value);

    list.appendChild(dt);
    list.appendChild(dd);
  }

  private formatValue(value:unknown):string {
    if (value === null || value === undefined || value === '') {
      return '–';
    }

    if (typeof value === 'string' && /^P/i.test(value)) {
      return this.formatDuration(value);
    }

    return String(value);
  }

  private formatDuration(value:string):string {
    try {
      return this.timezoneService.formattedDuration(value, 'hour');
    } catch {
      // The configuration may not be loaded yet (or in tests); fall back to the raw value.
      return value;
    }
  }

  private position(preview:HTMLElement, row:HTMLElement):void {
    const rowRect = row.getBoundingClientRect();
    const previewRect = preview.getBoundingClientRect();

    const top = Math.min(rowRect.top, window.innerHeight - previewRect.height - 8);
    const left = Math.min(rowRect.left + 16, window.innerWidth - previewRect.width - 8);

    preview.style.top = `${Math.max(8, top)}px`;
    preview.style.left = `${Math.max(8, left)}px`;
  }

  private rowFor(target:EventTarget|null):HTMLTableRowElement|null {
    return (target as HTMLElement|null)?.closest<HTMLTableRowElement>(`.${tableRowClassName}`) ?? null;
  }

  private clearTimer():void {
    if (this.showTimer !== undefined) {
      window.clearTimeout(this.showTimer);
      this.showTimer = undefined;
    }
  }

  private removePreview():void {
    this.preview?.remove();
    this.preview = null;
  }
}
