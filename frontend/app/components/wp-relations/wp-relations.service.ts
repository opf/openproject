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
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {RelationTitle} from "./wp-relations.interfaces";



export class WorkPackageRelationsService {
  constructor(protected $rootScope,
              protected $q,
              protected $state,
              protected I18n,
              protected wpCacheService,
              protected wpNotificationsService,
              protected NotificationsService) {

  }



  public addCommonRelation(workPackage, relationType, relatedWpId) {
    const params = {
      to_id: relatedWpId,
      relation_type: relationType
    };

    return workPackage.addRelation(params);
  }

  public changeRelationDescription(relation, description) {
    const params = {
      description: description
    };
    return relation.update(params);
  }

  public changeRelationType(relation, relationType) {
    const params = {
      relation_type: relationType
    };
    return relation.update(params);
  }

  public removeCommonRelation(relation, workPackage) {
    return relation.remove();
  }

  public getTranslatedRelationTitle(relationTypeName:string) {
    return this.getRelationTypeObjectByName(relationTypeName).label;
  }

  public getRelationTypeObjectByType(type:string) {
    return _.find(this.configuration.relationTypes, {type: type});
  }

  public getRelationTypeObjectByName(name:string) {
    return _.find(this.configuration.relationTypes, {name: name});
  }

  public getRelationTypes(rejectParentChild?:boolean) {

    let relationTypes = angular.copy(this.configuration.relationTypes);
    if (rejectParentChild) {
      _.remove(relationTypes, (relationType) => {
        return relationType.name === 'parent' || relationType.name === 'children';
      });
    }
    return relationTypes;
  }

  public configuration = {
    relationTypes: [
      {name: 'parent', type: 'parent', label: this.I18n.t('js.relation_labels.parent')},
      {name: 'children', type: 'children', label: this.I18n.t('js.relation_labels.children')},
      {name: 'relatedTo', type: 'Relation::Relates', id: 'relates', label: this.I18n.t('js.relation_labels.relates')},
      {name: 'duplicates', type: 'Relation::Duplicates', label: this.I18n.t('js.relation_labels.duplicates')},
      {name: 'duplicated', type: 'Relation::Duplicated', label: this.I18n.t('js.relation_labels.duplicated')},
      {name: 'blocks', type: 'Relation::Blocks', label: this.I18n.t('js.relation_labels.blocks')},
      {name: 'blocked', type: 'Relation::Blocked', label: this.I18n.t('js.relation_labels.blocked')},
      {name: 'precedes', type: 'Relation::Precedes', label: this.I18n.t('js.relation_labels.precedes')},
      {name: 'follows', type: 'Relation::Follows', label: this.I18n.t('js.relation_labels.follows')}
    ]
  };
}

wpDirectivesModule.service('WpRelationsService', WorkPackageRelationsService);
