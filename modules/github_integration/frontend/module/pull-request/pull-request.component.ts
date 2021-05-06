//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { Component, Input } from '@angular/core';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import { GithubCheckRunResource } from '../hal/resources/github-check-run-resource';
import { IGithubPullRequestResource } from "../../../../../../../../modules/github_integration/frontend/module/typings";

@Component({
  selector: 'github-pull-request',
  templateUrl: './pull-request.template.html',
  styleUrls: ['./pull-request.component.sass']
})
export class PullRequestComponent {
  @Input() public pullRequest:IGithubPullRequestResource;

  public text = {
    label_updated_on: this.I18n.t('js.label_updated_on'),
    label_details: this.I18n.t('js.label_details'),
    label_actions: this.I18n.t('js.github_integration.github_actions'),
  };

  constructor(readonly PathHelper:PathHelperService,
              readonly I18n:I18nService) {
  }

  get state() {
    if (this.pullRequest.state === 'open') {
      return (this.pullRequest.draft ? 'draft' : 'open');
    } else {
      return(this.pullRequest.merged ? 'merged' : 'closed');
    }
  }

  public checkRunState(checkRun:GithubCheckRunResource) {
    /* Github apps can *optionally* add an output object (and a title) which is the most relevant information to display.
       If that is not present, we can display the conclusion (which is present only on finished runs).
       If that is not present, we can always fall back to the status. */
    return(checkRun.outputTitle || checkRun.conclusion || checkRun.status);
  }
}
