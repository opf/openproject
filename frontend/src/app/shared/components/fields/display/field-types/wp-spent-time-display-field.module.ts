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

import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import URI from 'urijs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkDisplayField } from 'core-app/shared/components/fields/display/field-types/work-display-field.module';
import moment from 'moment-timezone';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

export class WorkPackageSpentTimeDisplayField extends WorkDisplayField {
  public text = {
    linkTitle: this.I18n.t('js.work_packages.message_view_spent_time'),
    logTime: this.I18n.t('js.button_log_time'),
  };

  @LazyInject() PathHelper:PathHelperService;

  @LazyInject() apiV3Service:ApiV3Service;

  @LazyInject() TurboRequests:TurboRequestsService;

  private closeDialogHandler:EventListener = this.handleDialogClose.bind(this);
  private workPackageForHandler:WorkPackageResource;

  public render(element:HTMLElement, displayText:string):void {
    if (!this.value) {
      return;
    }

    const link = document.createElement('a');
    link.textContent = displayText;
    link.setAttribute('title', this.text.linkTitle);

    if (displayText === this.placeholder) {
      link.setAttribute(
        'class',
        'time-logging--value time-logging--value_empty',
      );
    } else {
      link.setAttribute('class', 'time-logging--value');
    }

    if (this.resource.project && this.resource.id) {
      const wpID = this.resource.id.toString();
      this.apiV3Service.projects
        .id(this.resource.project as ProjectResource)
        .get()
        .subscribe((project:ProjectResource) => {
          // Link to the cost report having the work package filter preselected. No grouping.
          const href = URI(
            this.PathHelper.projectTimeEntriesPath(
              project.identifier,
            ),
          )
            .search(
              `fields[]=WorkPackageId&operators[WorkPackageId]=%3D_child_work_packages&values[WorkPackageId]=${wpID}&set_filter=1`,
            )
            .toString();

          link.href = href;
        });
    }

    element.innerHTML = '';
    element.appendChild(link);

    this.appendTimelogLink(element);
  }

  private appendTimelogLink(element:HTMLElement) {
    if (this.resource.logTime) {
      const timelogElement = document.createElement('a');
      timelogElement.setAttribute('class', 'icon icon-time');
      timelogElement.setAttribute('href', '');
      timelogElement.setAttribute('title', this.text.logTime);

      element.appendChild(timelogElement);

      timelogElement.addEventListener(
        'click',
        this.showTimelogWidget.bind(this, this.resource),
      );
    }
  }

  private showTimelogWidget(wp:WorkPackageResource) {
    document.addEventListener('dialog:close', this.closeDialogHandler);
    this.workPackageForHandler = wp;

    void this.TurboRequests.request(
      `${this.PathHelper.timeEntryWorkPackageDialog(wp.id!)}?date=${moment().format('YYYY-MM-DD')}`,
      { method: 'GET' },
    );
  }

  private handleDialogClose(event:CustomEvent):void {
    document.removeEventListener('dialog:close', this.closeDialogHandler);

    const {
      detail: { dialog, submitted },
    } = event as { detail:{ dialog:HTMLDialogElement; submitted:boolean } };
    if (dialog.id === 'time-entry-dialog' && submitted) {
      void this.apiV3Service.work_packages
        .id(this.workPackageForHandler.id!)
        .refresh();
    }
  }
}
