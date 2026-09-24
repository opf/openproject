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

import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { buildShowAllocationsButton, showAllocationsLink } from './show-allocations-button';

export class AllocatedTimeDisplayField extends DisplayField {
  @LazyInject() timezoneService:TimezoneService;

  @LazyInject() turboRequests:TurboRequestsService;

  public get valueString():string {
    return this.timezoneService.formattedChronicDuration(this.value as string);
  }

  public render(element:HTMLElement, displayText:string):void {
    element.innerHTML = '';

    const link = showAllocationsLink(this.resource);
    const container = link ? buildShowAllocationsButton(link, this.turboRequests) : document.createElement('span');
    container.classList.add('d-flex', 'flex-items-center');

    if (this.workDuration) {
      container.appendChild(this.buildProgressBar());
      container.appendChild(this.buildSummary(displayText, this.workDuration));
    } else {
      container.appendChild(document.createTextNode(displayText));
    }

    element.appendChild(container);
  }

  private get workDuration():string|null {
    const work = (this.resource.derivedEstimatedTime ?? this.resource.estimatedTime) as string|null;

    return work && this.timezoneService.toHours(work) > 0 ? work : null;
  }

  private get ratio():number {
    const allocatedHours = this.timezoneService.toHours(this.value as string);
    const workHours = this.timezoneService.toHours(this.workDuration!);

    return Math.round((allocatedHours / workHours) * 100);
  }

  private get barColorClass():string {
    if (this.ratio > 100) {
      return 'color-bg-danger-emphasis';
    }

    return this.ratio === 100 ? 'color-bg-success-emphasis' : 'color-bg-accent-emphasis';
  }

  private buildProgressBar():HTMLElement {
    const bar = document.createElement('span');
    bar.classList.add('Progress', 'op-rm-allocated-time--bar');

    const item = document.createElement('span');
    item.classList.add('Progress-item', this.barColorClass);
    item.style.width = `${Math.min(this.ratio, 100)}%`;

    bar.appendChild(item);

    return bar;
  }

  private buildSummary(displayText:string, workDuration:string):HTMLElement {
    const summary = document.createElement('span');
    summary.classList.add('ml-2', 'flex-shrink-0');
    summary.textContent = `${displayText} / ${this.timezoneService.formattedChronicDuration(workDuration)} `;

    const percentage = document.createElement('span');
    percentage.classList.add('color-fg-muted');
    percentage.textContent = `(${this.ratio}%)`;

    summary.appendChild(percentage);

    return summary;
  }
}
