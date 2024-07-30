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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, Injector, OnDestroy } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { WpRelationInlineAddExistingComponent } from 'core-app/features/work-packages/components/wp-relations/embedded/inline/add-existing/wp-relation-inline-add-existing.component';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { WpRelationInlineCreateServiceInterface } from 'core-app/features/work-packages/components/wp-relations/embedded/wp-relation-inline-create.service.interface';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import {
  Observable,
  of,
} from 'rxjs';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

@Injectable()
export class WpRelationInlineCreateService extends WorkPackageInlineCreateService implements WpRelationInlineCreateServiceInterface, OnDestroy {
  @InjectField() wpRelations:WorkPackageRelationsService;

  constructor(public injector:Injector) {
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
    return this.wpRelations.addCommonRelation(toId, this.relationType, from.id!);
  }

  /**
   * Remove a given relation
   */
  public remove(from:WorkPackageResource, to:WorkPackageResource):Promise<unknown> {
    // Find the relation matching relationType and from->to which are unique together
    const relation = this.wpRelations.find(to, from, this.relationType);

    if (relation !== undefined) {
      return this.wpRelations.removeRelation(relation);
    }
    return Promise.reject();
  }

  /**
   * A related work package for the inline create context
   */
  public referenceTarget:WorkPackageResource|null = null;

  public get canAdd():Observable<boolean> {
    if (!this.referenceTarget?.addRelation) {
      return of(false);
    }

    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    return this.canCreateWorkPackages(idFromLink(this.referenceTarget.project.href));
  }

  public get canReference():Observable<boolean> {
    return this.canAdd;
  }

  /**
   * Reference button text
   */
  public readonly buttonTexts = {
    reference: this.I18n.t('js.relation_buttons.add_existing'),
    create: this.I18n.t('js.relation_buttons.create_new'),
  };
}
