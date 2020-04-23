// -- copyright
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
// ++

import {Injectable, Injector} from '@angular/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WpRelationInlineCreateServiceInterface} from "core-components/wp-relations/embedded/wp-relation-inline-create.service.interface";
import {WpRelationInlineAddExistingComponent} from "core-components/wp-relations/embedded/inline/add-existing/wp-relation-inline-add-existing.component";

@Injectable()
export class WpChildrenInlineCreateService extends WorkPackageInlineCreateService implements WpRelationInlineCreateServiceInterface {

  constructor(readonly injector:Injector,
              protected readonly wpRelationsHierarchyService:WorkPackageRelationsHierarchyService) {
    super(injector);
  }

  /**
   * A separate reference pane for the inline create component
   */
  public readonly referenceComponentClass = WpRelationInlineAddExistingComponent;

  /**
   * Define the reference type
   */
  public relationType:string = 'children';

  /**
   * Add a new relation of the above type
   */
  public add(from:WorkPackageResource, toId:string):Promise<unknown> {
    return this.wpRelationsHierarchyService.addExistingChildWp(from, toId);
  }

  /**
   * Remove a given relation
   */
  public remove(from:WorkPackageResource, to:WorkPackageResource):Promise<unknown> {
    return this.wpRelationsHierarchyService.removeChild(to);
  }

  /**
   * A related work package for the inline create context
   */
  public referenceTarget:WorkPackageResource|null = null;

  public get canAdd() {
    return !!(this.referenceTarget && this.canCreateWorkPackages && this.canAddChild);
  }

  public get canReference() {
    return !!(this.referenceTarget && this.canAddChild);
  }

  public get canAddChild() {
    const wp = this.referenceTarget;
    return wp && !wp.isMilestone && wp.changeParent;
  }

  /**
   * Reference button text
   */
  public readonly buttonTexts = {
    reference: this.I18n.t('js.relation_buttons.add_existing_child'),
    create: this.I18n.t('js.relation_buttons.add_new_child')
  };
}
