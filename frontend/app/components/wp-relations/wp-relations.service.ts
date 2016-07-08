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

import {wpTabsModule} from '../../angular-modules';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';

export interface WorkPackageRelationsConfigInterface {
  name:string;
  type:string;
  id?:string;
}

export class WorkPackageRelationsService {
  private relationsConfig:WorkPackageRelationsConfigInterface[] = [
    {name: 'parent', type: 'parent'},
    {name: 'children', type: 'children'},
    {name: 'relatedTo', type: 'Relation::Relates', id: 'relates'},
    {name: 'duplicates', type: 'Relation::Duplicates'},
    {name: 'duplicated', type: 'Relation::Duplicated'},
    {name: 'blocks', type: 'Relation::Blocks'},
    {name: 'blocked', type: 'Relation::Blocked'},
    {name: 'precedes', type: 'Relation::Precedes'},
    {name: 'follows', type: 'Relation::Follows'}
  ];

  constructor(protected WorkPackageRelationGroup,
              protected WorkPackageParentRelationGroup,
              protected WorkPackageChildRelationsGroup) {
  }

  public getWpRelationGroups(workPackage:WorkPackageResourceInterface) {
    let configsOfInterest = this.relationsConfig;

    if (workPackage.isMilestone) {
      configsOfInterest = _.reject(configsOfInterest, {name: 'children'});
    }

    return configsOfInterest.map(config => {
      switch (config.type) {
        case 'parent':
          return new this.WorkPackageParentRelationGroup(workPackage, config);
        case 'children':
          return new this.WorkPackageChildRelationsGroup(workPackage, config);
        default:
          return new this.WorkPackageRelationGroup(workPackage, config);
      }
    });
  }
}

wpTabsModule.service('wpRelations', WorkPackageRelationsService);
