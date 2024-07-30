//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2023 Ben Tey
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
// Copyright (C) the OpenProject GmbH
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
//++

import { Component, Input } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {IGitlabMergeRequestResource} from 'core-app/features/plugins/linked/openproject-gitlab_integration/typings';

@Component({
  selector: 'gitlab-merge-request',
  templateUrl: './merge-request.component.html',
  styleUrls: [
    './merge-request.component.sass',
    './mr-pipeline.component.sass',
  ],
  host: { class: 'op-merge-request' }
})

export class MergeRequestComponent {
  @Input() public mergeRequest:IGitlabMergeRequestResource;

  public text = {
    label_created_by: this.I18n.t('js.label_created_by'),
    label_last_updated_on: this.I18n.t('js.gitlab_integration.updated_on'),
    label_details: this.I18n.t('js.label_details'),
    label_pipelines: this.I18n.t('js.gitlab_integration.gitlab_pipelines'),
  };

  constructor(readonly PathHelper:PathHelperService,
              readonly I18n:I18nService) {
  }

  get state() {

    if (this.mergeRequest.state === 'opened') {
      return (this.mergeRequest.draft ? 'open' : 'ready');
    } else {
      return(this.mergeRequest.merged ? 'merged' : 'closed');
    }
  }

  toggleLabels(identifier: string) {
    const labelsElement = document.querySelector(`.op-merge-request--labels-${identifier}`) as HTMLElement;

    // Check the current display property and toggle it
    labelsElement.style.display = labelsElement.style.display === 'none' ? 'block' : 'none';
  }

  get pipelineIconClass():string {
    return this.mergeRequest.pipelines ? 'op-merge-request--pipeline-icon_' + this.mergeRequest.pipelines[0].status : '';
  }

  isCurrentPipelinestate(status:string):boolean {
    return !!this.mergeRequest.pipelines && this.mergeRequest.pipelines[0].status === status;
  }
}
