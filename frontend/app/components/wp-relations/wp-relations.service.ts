import {multiInput, State, StatesGroup} from 'reactivestates';
import {opServicesModule} from '../../angular-modules';
import {CollectionResource} from '../api/api-v3/hal-resources/collection-resource.service';
import {
  RelationResource,
  RelationResourceInterface
} from '../api/api-v3/hal-resources/relation-resource.service';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {RelationsDmService} from '../api/api-v3/hal-resource-dms/wp-relations.service';
import {WorkPackageTableRefreshService} from '../wp-table/wp-table-refresh-request.service';

export type RelationsStateValue = { [relationId:number]:RelationResource };

export class WorkPackageRelationsService extends StatesGroup {

  name = 'WP-Relations';

  private relations = multiInput<RelationsStateValue>();

  /*@ngInject*/
  constructor(private relationsDm:RelationsDmService,
              private wpTableRefresh:WorkPackageTableRefreshService,
              private PathHelper:any) {
    super();
    this.initializeMembers();
  }

  getRelationsForWorkPackage(workPackageId:string):State<RelationsStateValue> {
    return this.relations.get(workPackageId);
  }

  /**
   * Require the relations of the given singular work package to be loaded into its state.
   */
  require(workPackage:WorkPackageResourceInterface, force:boolean = false) {
    const state = this.relations.get(workPackage.id);

    if (force) {
      state.clear();
    }

    if (state.isPristine()) {
      workPackage.relations.$load(true).then((collection:CollectionResource) => {
        if (collection.elements.length > 0) {
          this.mergeIntoStates(collection.elements as RelationResource[]);
        } else {
          this.relations.get(workPackage.id).putValue({},
            "Received empty response from singular relations");
        }
      });
    }
  }

  /**
   * Require the relations of a set of involved work packages loaded into the states.
   */
  requireInvolved(workPackageIds:string[]):ng.IPromise<RelationResource[]> {
    return this.relationsDm
      .loadInvolved(workPackageIds)
      .then((elements:RelationResource[]) => {
        this.mergeIntoStates(elements);
        return elements;
      });
  }

  /**
   * Remove the given relation.
   */
  public removeRelation(relation:RelationResourceInterface) {
    return relation.delete().then(() => {
      _.each(relation.ids, (member:string) => {
        const state = this.relations.get(member);
        const currentValue = state.value!;

        if (currentValue !== null) {
          delete currentValue[relation.id];
          state.putValue(currentValue);
        }
      });
      this.wpTableRefresh.request(true,
        `Removing relation (${relation.ids.from} to ${relation.ids.to})`);
    });
  }

  /**
   * Update the given relation
   */
  public updateRelation(workPackageId:string, relation:RelationResourceInterface, params:any) {
    return relation.updateImmediately(params)
      .then((savedRelation:RelationResourceInterface) => {
        this.mergeIntoStates([savedRelation]);
        this.wpTableRefresh.request(true,
          `Updating relation (${relation.ids.from} to ${relation.ids.to})`);
        return savedRelation;
      });
  }

  public addCommonRelation(workPackage:WorkPackageResourceInterface,
                           relationType:string,
                           relatedWpId:string) {
    const params = {
      _links: {
        from: {href: workPackage.href},
        to: {href: this.PathHelper.apiV3WorkPackagePath(relatedWpId)}
      },
      type: relationType
    };

    return workPackage.addRelation(params).then((relation:RelationResourceInterface) => {
      this.mergeIntoStates([relation]);
      this.wpTableRefresh.request(true,
        `Adding relation (${relation.ids.from} to ${relation.ids.to})`);
      return relation;
    });
  }

  /**
   * Merge a set of relations into the associated states
   */
  private mergeIntoStates(elements:RelationResource[]) {
    const stateValues = this.accumulateRelationsFromCollection(elements);
    _.each(stateValues, (relations:RelationResource[], workPackageId:string) => {
      this.merge(workPackageId, relations);
    });
  }

  /**
   * Merge an object of relations into the associated state or create it, if empty.
   */
  private merge(workPackageId:string, newRelations:RelationResource[]) {
    const state = this.relations.get(workPackageId);
    let relationsToInsert = _.keyBy(newRelations, r => r.id);
    let current = state.value!;

    if (current !== null) {
      relationsToInsert = _.assign(current, relationsToInsert);
    }

    state.putValue(relationsToInsert, "Initializing relations state.");
  }

  /**
   *
   * We don't know how many values we're getting for a single work package
   * So accumlate the state values before pushing them once.
   */
  private accumulateRelationsFromCollection(relations:RelationResource[]) {
    const stateValues:{ [workPackageId:string]:RelationResource[] } = {};

    relations.forEach((relation:RelationResource) => {
      const involved = relation.ids;

      if (!stateValues[involved.from]) {
        stateValues[involved.from] = [];
      }
      if (!stateValues[involved.to]) {
        stateValues[involved.to] = [];
      }

      stateValues[involved.from].push(relation);
      stateValues[involved.to].push(relation);
    });

    return stateValues;
  }

}

opServicesModule.service('wpRelations', WorkPackageRelationsService);
