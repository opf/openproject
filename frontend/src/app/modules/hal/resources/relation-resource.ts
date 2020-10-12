//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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

import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';

export interface RelationResourceLinks {
  delete():Promise<any>;

  updateImmediately(payload:any):Promise<any>;
}

export class RelationResource extends HalResource {

  static RELATION_TYPES(includeParentChild:boolean = true):string[] {
    const types = [
      'relates',
      'duplicates',
      'duplicated',
      'blocks',
      'blocked',
      'precedes',
      'follows',
      'includes',
      'partof',
      'requires',
      'required'
    ];

    if (includeParentChild) {
      types.push('parent', 'children');
    }

    return types;
  }

  static LOCALIZED_RELATION_TYPES(includeParentchild:boolean = true) {
    const relationTypes = RelationResource.RELATION_TYPES(includeParentchild);

    return relationTypes.map((key:string) => {
      return {name: key, label: I18n.t('js.relation_labels.' + key)};
    });
  }

  static DEFAULT() {
    return 'relates';
  }

  // Properties
  public description:string|null;
  public name:string;
  public type:any;
  public reverseType:string;

  // Links
  public $links:RelationResourceLinks;
  public to:WorkPackageResource;
  public from:WorkPackageResource;

  public normalizedType(workPackage:WorkPackageResource) {
    return this.denormalized(workPackage).relationType;
  }

  /**
   * Return the denormalized relation data, seeing the relation.from to be `workPackage`.
   *
   * @param workPackage
   * @return {{id, href, relationType: string, workPackageType}}
   */
  public denormalized(workPackage:WorkPackageResource):DenormalizedRelationData {
    const target = (this.to.href === workPackage.$href) ? 'from' : 'to';

    return {
      target: this[target],
      targetId: this[target].id!,
      relationType: target === 'from' ? this.reverseType : this.type,
      reverseRelationType: target === 'from' ? this.type : this.reverseType
    };
  }

  /**
   * Return whether the given work package id is involved in this relation.
   * @param wpId
   * @return {boolean}
   */
  public isInvolved(wpId:string) {
    return _.values(this.ids).indexOf(wpId.toString()) >= 0;
  }

  /**
   * Get the involved IDs, returning an object to the ids.
   */
  public get ids() {
    return {
      from: WorkPackageResource.idFromLink(this.from.href!),
      to: WorkPackageResource.idFromLink(this.to.href!)
    };
  }

  public updateDescription(description:string) {
    return this.$links.updateImmediately({description: description});
  }

  public updateType(type:any) {
    return this.$links.updateImmediately({type: type});
  }
}

export interface RelationResource extends RelationResourceLinks {
}

export interface DenormalizedRelationData {
  target:WorkPackageResource;
  targetId:string;
  relationType:string;
  reverseRelationType:string;
}

