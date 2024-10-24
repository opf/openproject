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

import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { Observable, zip } from 'rxjs';
import { take, takeUntil } from 'rxjs/operators';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { componentDestroyed } from '@w11k/ngx-componentdestroyed';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { RelationsStateValue, WorkPackageRelationsService } from './wp-relations.service';
import { RelatedWorkPackagesGroup } from './wp-relations.interfaces';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Component({
  selector: 'wp-relations',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './wp-relations.template.html',
})
export class WorkPackageRelationsComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  public relationGroups:RelatedWorkPackagesGroup = {};

  public relationGroupKeys:string[] = [];

  public relationsPresent = false;

  public canAddRelation:boolean;

  // By default, group by relation type
  public groupByWorkPackageType = false;

  public text = {
    relations_header: this.I18n.t('js.work_packages.tabs.relations'),
  };

  public currentRelations:WorkPackageResource[] = [];

  turboFrameSrc:string;

  constructor(
  private I18n:I18nService,
    private wpRelations:WorkPackageRelationsService,
    private cdRef:ChangeDetectorRef,
    private apiV3Service:ApiV3Service,
    private PathHelper:PathHelperService,
) {
    super();
  }

  ngOnInit() {
    this.turboFrameSrc = `${this.PathHelper.staticBase}/work_packages/${this.workPackage.id}/relations_tab`;
    this.canAddRelation = !!this.workPackage.addRelation;

    this.wpRelations
      .state(this.workPackage.id!)
      .values$()
      .pipe(
        takeUntil(componentDestroyed(this)),
      )
      .subscribe((relations:RelationsStateValue) => {
        this.loadedRelations(relations);
      });

    this.wpRelations.require(this.workPackage.id!);

    // Listen for changes to this WP.
    this
      .apiV3Service
      .work_packages
      .id(this.workPackage)
      .requireAndStream()
      .pipe(
        takeUntil(componentDestroyed(this)),
      )
      .subscribe((wp:WorkPackageResource) => {
        this.workPackage = wp;
      });
  }

  private getRelatedWorkPackages(workPackageIds:string[]):Observable<WorkPackageResource[]> {
    const observablesToGetZipped:Observable<WorkPackageResource>[] = workPackageIds.map((wpId) => this
      .apiV3Service
      .work_packages
      .id(wpId)
      .get());

    return zip(...observablesToGetZipped);
  }

  protected getRelatedWorkPackageId(relation:RelationResource):string {
    const involved = relation.ids;
    return (relation.to.href === this.workPackage.href) ? involved.from : involved.to;
  }

  public toggleGroupBy() {
    this.groupByWorkPackageType = !this.groupByWorkPackageType;
    this.buildRelationGroups();
  }

  protected buildRelationGroups() {
    if (_.isNil(this.currentRelations)) {
      return;
    }

    this.relationGroups = <RelatedWorkPackagesGroup>_.groupBy(
this.currentRelations,
      (wp:WorkPackageResource) => {
        if (this.groupByWorkPackageType) {
          return wp.type.name;
        }
        const normalizedType = (wp.relatedBy as RelationResource).normalizedType(this.workPackage);
        return this.I18n.t(`js.relation_labels.${normalizedType}`);
      },
);
    this.relationGroupKeys = _.keys(this.relationGroups);
    this.relationsPresent = _.size(this.relationGroups) > 0;
    this.cdRef.detectChanges();
  }

  protected loadedRelations(stateValues:RelationsStateValue):void {
    const relatedWpIds:string[] = [];
    const relations:{ [wpId:string]:any } = [];

    if (_.size(stateValues) === 0) {
      this.currentRelations = [];
      return this.buildRelationGroups();
    }

    _.each(stateValues, (relation:RelationResource) => {
      const relatedWpId = this.getRelatedWorkPackageId(relation);
      relatedWpIds.push(relatedWpId);
      relations[relatedWpId] = relation;
    });

    this.getRelatedWorkPackages(relatedWpIds)
      .pipe(
        take(1),
      )
      .subscribe((relatedWorkPackages:WorkPackageResource[]) => {
        this.currentRelations = relatedWorkPackages.map((wp:WorkPackageResource) => {
          wp.relatedBy = relations[wp.id!];
          return wp;
        });

        this.buildRelationGroups();
      });
  }
}
