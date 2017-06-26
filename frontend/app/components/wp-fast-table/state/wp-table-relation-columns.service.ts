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

import {opServicesModule} from '../../../angular-modules';
import {States} from '../../states.service';
import {WorkPackageTableRelationColumns} from '../wp-table-relation-columns';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTableColumnsService} from './wp-table-columns.service';
import {TableStateStates, WorkPackageTableBaseService} from './wp-table-base.service';
import {RelationResource} from '../../api/api-v3/hal-resources/relation-resource.service';
import {
  QueryColumn, queryColumnTypes, RelationQueryColumn,
  TypeRelationQueryColumn
} from '../../wp-query/query-column';
import {IQService} from 'angular';
import {HalRequestService} from '../../api/api-v3/hal-request/hal-request.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {
  RelationsStateValue,
  WorkPackageRelationsService
} from '../../wp-relations/wp-relations.service';

export type RelationColumnType = 'toType' | 'ofType';

export class WorkPackageTableRelationColumnsService extends WorkPackageTableBaseService {
  protected stateName = 'relationColumns' as TableStateStates;

  constructor(public states:States,
              public wpTableColumns:WorkPackageTableColumnsService,
              public $q:IQService,
              public halRequest:HalRequestService,
              public wpCacheService:WorkPackageCacheService,
              public wpRelations:WorkPackageRelationsService) {
    super(states);
  }

  public initialize(workPackages:WorkPackageResourceInterface[]) {
    this.initializeState();
  }

  /**
   * Returns a subset of all relations that the user has currently expanded.
   *
   * @param workPackage
   * @param relation
   */
  public relationsToExtendFor(workPackage:WorkPackageResourceInterface,
                              relations:RelationsStateValue|undefined,
                              eachCallback:(relation:RelationResource, column:QueryColumn, type:RelationColumnType) => void) {
    // Only if any relation columns or stored expansion state exist
    if (!this.wpTableColumns.hasRelationColumns() || this.state.isPristine()) {
      return;
    }

    // Only if any relations exist for this work package
    if (_.isNil(relations)) {
      return;
    }

    // Only if the work package has anything expanded
    const expanded = this.current.getExpandFor(workPackage.id);
    if (expanded === undefined) {
      return;
    }

    const column = this.wpTableColumns.findById(expanded)!;
    const type = this.relationColumnType(column);

    if (type !== null) {
      _.each(this.relationsForColumn(workPackage, relations, column),
        (relation) => eachCallback(relation as RelationResource, column, type));
    }
  }

  /**
   * Get the subset of relations for the work package that belong to this relation column
   *
   * @param workPackage A work package resource
   * @param relations The RelationStateValue of this work package
   * @param column The relation column to filter for
   * @return The filtered relations
   */
  public relationsForColumn(workPackage:WorkPackageResourceInterface, relations:RelationsStateValue|undefined, column:QueryColumn) {
    if (_.isNil(relations)) {
      return [];
    }

    // Get the type of TO work package
    const type = this.relationColumnType(column);
    if (type === 'toType') {
      const typeHref = (column as TypeRelationQueryColumn).type.href;

      return _.filter(relations, (relation:RelationResource) => {
        const denormalized = relation.denormalized(workPackage);
        const target = this.states.workPackages.get(denormalized.targetId).value!;

        return target.type.href === typeHref;
      });
    }

    // Get the relation types for OF relation columns
    if (type === 'ofType') {
      const relationType = (column as RelationQueryColumn).relationType;

      return _.filter(relations, (relation:RelationResource) => {
        return relation.denormalized(workPackage).relationType === relationType;
      });
    }

    return [];
  }

  public relationColumnType(column:QueryColumn):RelationColumnType|null {
    switch(column._type) {
      case queryColumnTypes.RELATION_TO_TYPE:
        return 'toType';
      case queryColumnTypes.RELATION_OF_TYPE:
        return 'ofType';
      default:
        return null;
    }
  }

  public getExpandFor(workPackageId:string):string | undefined {
    return this.current && this.current.getExpandFor(workPackageId);
  }

  public expandFor(workPackageId:string, columnId:string) {
    const current = this.current;

    current.expandFor(workPackageId, columnId);
    this.state.putValue(current);
  }

  public collapse(workPackageId:string) {
    const current = this.current;

    current.collapse(workPackageId);
    this.state.putValue(current);
  }

  public get current():WorkPackageTableRelationColumns {
    return this.state.value!;
  }

  private initializeState() {
    let current = this.current;

    if (!current) {
      current = new WorkPackageTableRelationColumns();
    }
    this.state.putValue(current);

    return current;
  }
}

opServicesModule.service('wpTableRelationColumns', WorkPackageTableRelationColumnsService);
