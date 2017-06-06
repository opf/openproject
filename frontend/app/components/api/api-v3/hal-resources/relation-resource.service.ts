import {opApiModule} from "../../../../angular-modules";
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
import {HalResource} from "./hal-resource.service";
import {WorkPackageResource, WorkPackageResourceInterface} from "./work-package-resource.service";

interface RelationResourceLinks {
  delete(): ng.IPromise<any>;
  updateImmediately(payload: any): ng.IPromise<any>;
  toType:{ href:string };
  fromType:{ href:string };
}

export class RelationResource extends HalResource {

  static TYPES():string[] {
    return [
      'parent',
      'children',
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
  }

  static DEFAULT() {
    return 'relates';
  }

  // Properties
  public id:number;
  public description:string|null;
  public name:string;
  public type:any;
  public reverseType:string;

  // Links
  public $links: RelationResourceLinks;
  public to:WorkPackageResource;
  public from:WorkPackageResource;

  public normalizedType(workPackage:WorkPackageResourceInterface) {
    return this.denormalized(workPackage).relationType;
  }

  /**
   * Return the denormalized relation data, seeing the relation.from to be `workPackage`.
   *
   * @param workPackage
   * @return {{id, href, relationType: string, workPackageType}}
   */
  public denormalized(workPackage:WorkPackageResourceInterface) {
    const target = (this.to.href === workPackage.href) ? 'from' : 'to'

    return {
      target: this[target],
      relationType: target === 'from' ? this.reverseType : this.type,
      workPackageType: this[target + 'Type'].href
    };
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
    return this.$links.updateImmediately({ description: description });
  }

  public updateType(type:any) {
    return this.$links.updateImmediately({ type: type });
  }
}

export interface RelationResourceInterface extends RelationResourceLinks, RelationResource {
}

function relationResource() {
  return RelationResource;
}

opApiModule.factory('RelationResource', relationResource);
