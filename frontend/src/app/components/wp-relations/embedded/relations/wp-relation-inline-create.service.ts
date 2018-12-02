// -- copyright
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
// ++

import {Injectable, Injector, OnDestroy} from '@angular/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WpRelationInlineAddExistingComponent} from "core-components/wp-relations/embedded/inline/add-existing/wp-relation-inline-add-existing.component";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {WorkPackageRelationsService} from "core-components/wp-relations/wp-relations.service";
import {RelationResource} from "core-app/modules/hal/resources/relation-resource";
import {WpRelationInlineCreateServiceInterface} from "core-components/wp-relations/embedded/wp-relation-inline-create.service.interface";

@Injectable()
export class WpRelationInlineCreateService extends WorkPackageInlineCreateService implements WpRelationInlineCreateServiceInterface, OnDestroy {

  protected readonly wpRelations:WorkPackageRelationsService = this.injector.get(WorkPackageRelationsService);

  constructor(protected readonly injector:Injector) {
    super(injector);
  }

  /**
   * A separate reference pane for the inline create component
   */
  public readonly referenceComponentClass = WpRelationInlineAddExistingComponent;

  /**
   * Defines the relation type for the relations inline create
   */
  public relationType = '';

  /**
   * Add a new relation of the above type
   */
  public add(from:WorkPackageResource, toId:string):Promise<unknown> {
    return this.wpRelations.addCommonRelation(toId, this.relationType, from.id);
  }

  /**
   * Remove a given relation
   */
  public remove(from:WorkPackageResource, to:WorkPackageResource):Promise<unknown> {
    // Find the relation matching relationType and from->to which are unique together
    const relation = this.wpRelations.find(to, from, this.relationType);

    if (relation !== undefined) {
      return this.wpRelations.removeRelation(relation);
    } else {
      return Promise.reject();
    }
  }

  /**
   * A related work package for the inline create context
   */
  public referenceTarget:WorkPackageResource|null = null;


  public get canAdd() {
    return !!(this.referenceTarget && this.canCreateWorkPackages && this.referenceTarget.addRelation);
  }

  public get canReference() {
    return !!this.canAdd;
  }

  /**
   * Reference button text
   */
  public readonly buttonTexts = {
    reference: this.I18n.t('js.relation_buttons.add_existing'),
    create: this.I18n.t('js.relation_buttons.create_new')
  };

  /**
   * Ensure hierarchical injected versions of this service correctly unregister
   */
  ngOnDestroy() {
    super.ngOnDestroy();
  }

}
