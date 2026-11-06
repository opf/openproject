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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';
import { HalResource, HalResourceLinks } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

export interface RelationResourceLinks {
  delete:CallableHalLink;

  updateImmediately:CallableHalLink<RelationResource>;
}

export class RelationResource extends HalResource implements RelationResourceLinks {
  static RELATION_TYPES(includeParentChild = true):string[] {
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
      'required',
    ];

    if (includeParentChild) {
      types.push('parent', 'children');
    }

    return types;
  }

  static LOCALIZED_RELATION_TYPES(includeParentchild = true) {
    const relationTypes = RelationResource.RELATION_TYPES(includeParentchild);

    return relationTypes.map((key:string) => ({ name: key, label: I18n.t(`js.relation_labels.${key}`) }));
  }

  static DEFAULT() {
    return 'relates';
  }

  // Properties
  public description:string|null;

  public type:string;

  public reverseType:string;

  // Links
  public $links:RelationResourceLinks & HalResourceLinks;

  public delete:CallableHalLink;

  public updateImmediately:CallableHalLink<RelationResource>;

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
    const target = (this.to.href === workPackage.href) ? 'from' : 'to';

    return {
      target: this[target],
      targetId: this[target].id!,
      relationType: target === 'from' ? this.reverseType : this.type,
      reverseRelationType: target === 'from' ? this.type : this.reverseType,
    };
  }

  /**
   * Return whether the given work package id is involved in this relation.
   * @param wpId
   * @return {boolean}
   */
  public isInvolved(wpId:string) {
    return Object.values(this.ids).includes(wpId.toString());
  }

  /**
   * Get the involved IDs, returning an object to the ids.
   */
  public get ids() {
    return {
      from: idFromLink(this.from.href),
      to: idFromLink(this.to.href),
    };
  }

  public updateDescription(description:string) {
    return this.$links.updateImmediately({ description });
  }

  public updateType(type:string) {
    return this.$links.updateImmediately({ type });
  }
}

export interface DenormalizedRelationData {
  target:WorkPackageResource;
  targetId:string;
  relationType:string;
  reverseRelationType:string;
}
