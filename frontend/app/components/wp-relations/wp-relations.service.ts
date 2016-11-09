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

import {wpDirectivesModule} from '../../angular-modules';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../wp-edit/wp-notification.service';
import {RelationResource} from '../api/api-v3/hal-resources/relation-resource.service';

export class WorkPackageRelationsService {
  constructor(protected $rootScope:ng.IRootScopeService,
              protected $q:ng.IQService,
              protected wpCacheService:WorkPackageCacheService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected I18n:op.I18n,
              protected PathHelper,
              protected NotificationsService) {
  }

  public addCommonRelation(workPackage, relationType, relatedWpId) {
    const params = {
      _links: {
        from: { href: workPackage.href },
        to: { href: this.PathHelper.apiV3WorkPackagePath(relatedWpId) }
      },
      type: relationType
    };

    return workPackage.addRelation(params);
  }

  public getRelationTypes(rejectParentChild?:boolean):any[] {
    let relationTypes = RelationResource.TYPES();

    if (rejectParentChild) {
      _.pull(relationTypes, 'parent', 'children');
    }

    return relationTypes.map((key:string) => {
      return { name: key, label: this.I18n.t('js.relation_labels.' + key) };
    });
  }
}

wpDirectivesModule.service('wpRelationsService', WorkPackageRelationsService);
