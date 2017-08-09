//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {wpControllersModule} from '../../../angular-modules';
import {States} from '../../states.service';
import {WorkPackagesListService} from '../../wp-list/wp-list.service';
import {QueryResource} from '../../api/api-v3/hal-resources/query-resource.service';

export class ShareModalController {
  public query:QueryResource;
  public name:string = 'Share';

  public isStarred:boolean;
  public isPublic:boolean;

  constructor(private shareModal:any,
              private states:States,
              private NotificationsService:any,
              private wpListService:WorkPackagesListService,
              private $q:ng.IQService) {
    this.name = 'Share';
    this.query = this.states.query.resource.value!;

    this.isStarred = this.query.starred;
    this.isPublic = this.query.public;
  }

  public setValues(isStarred:boolean, isPublic:boolean) {
    this.isStarred = isStarred;
    this.isPublic = isPublic;
  }

  public closeModal() {
    this.shareModal.deactivate();
  }

  public closeAndReport(message:any) {
    this.shareModal.deactivate();
    this.NotificationsService.addSuccess(message.text);
  }

  public saveQuery() {
    let promises = [];

    if (this.query.public !== this.isPublic) {
      this.query.public = this.isPublic;

      promises.push(this.wpListService.save(this.query));
    }

    if (this.query.starred !== this.isStarred) {
      promises.push(this.wpListService.toggleStarred(this.query));
    }

    this.$q.all(promises).then(() => {
      this.shareModal.deactivate();
    });
  };
}

wpControllersModule.controller('ShareModalController', ShareModalController);
