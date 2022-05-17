// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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

import {
  ChangeDetectionStrategy, Component, Input, OnInit,
} from '@angular/core';
import { Moment } from 'moment-timezone';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { IUser } from 'core-app/core/state/principals/user.model';

@Component({
  templateUrl: './authoring.component.html',
  styleUrls: ['./authoring.component.sass'],
  selector: 'op-authoring',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AuthoringComponent implements OnInit {
  @Input() createdOn:string;

  @Input() author:IUser;

  @Input() showAuthorAsLink:boolean;

  public createdOnTime:Moment;

  public timeago:string;

  public time:string;

  public get authorName():string {
    return (this.author && this.author.name) || '';
  }

  public get authorLink():string {
    return (this.author && this.PathHelper.userPath(this.author.id)) || '';
  }

  public constructor(readonly PathHelper:PathHelperService, readonly timezoneService:TimezoneService) { }

  ngOnInit():void {
    this.createdOnTime = this.timezoneService.parseDatetime(this.createdOn);
    this.timeago = this.createdOnTime.fromNow();
    this.time = this.createdOnTime.format('LLL');
  }
}
