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

import { Component, Input, OnInit } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { TimezoneService } from 'core-components/datetime/timezone.service';

@Component({
  templateUrl: './authoring.html',
  styleUrls: ['./authoring.sass'],
  selector: 'authoring',
})
export class AuthoringComponent implements OnInit {
  // scope: { createdOn: '=', author: '=', showAuthorAsLink: '=', project: '=', activity: '=' },
  @Input('createdOn') createdOn:string;
  @Input('author') author:HalResource;
  @Input('showAuthorAsLink') showAuthorAsLink:boolean;
  @Input('project') project:any;
  @Input('activity') activity:any;

  public createdOnTime:any;
  public timeago:any;
  public time:any;
  public userLink:string;

  public constructor(readonly PathHelper:PathHelperService,
                     readonly I18n:I18nService,
                     readonly timezoneService:TimezoneService) {

  }

  ngOnInit() {
    this.createdOnTime = this.timezoneService.parseDatetime(this.createdOn);
    this.timeago = this.createdOnTime.fromNow();
    this.time = this.createdOnTime.format('LLL');
    this.userLink = this.PathHelper.userPath(this.author.idFromLink);
  }

  public activityFromPath(from:any) {
    var path = this.PathHelper.projectActivityPath(this.project);

    if (from) {
      path += '?from=' + from;
    }

    return path;
  }
}
