import {multiInput, State, StatesGroup} from 'reactivestates';
import {CollectionResource} from '../api/api-v3/hal-resources/collection-resource.service';
import {
  RelationResource,
  RelationResourceInterface
} from '../api/api-v3/hal-resources/relation-resource.service';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {RelationsDmService} from '../api/api-v3/hal-resource-dms/relations-dm.service';
import {WorkPackageTableRefreshService} from '../wp-table/wp-table-refresh-request.service';
import {opServicesModule} from '../../angular-modules';
import {Observable} from 'rxjs';
import {StateCacheService} from '../states/state-cache.service';

export type RelationsStateValue = { [relationId:number]:RelationResource };

class RelationStateGroup extends StatesGroup {
  name = 'WP-Relations';

  relations = multiInput<RelationsStateValue>();

  constructor() {
    super();
    this.initializeMembers();
  }
}

export class WorkPackageRelationsService extends StateCacheService<RelationsStateValue> {

  private relationStates:RelationStateGroup;

  /*@ngInject*/
  constructor(private relationsDm:RelationsDmService,
              private wpTableRefresh:WorkPackageTableRefreshService,
              private $q:ng.IQService,
              private PathHelper:any) {
    super();
    this.relationStates = new RelationStateGroup();
  }

  protected get multiState() {
    return this.relationStates.relations;
  }

  /**
   * Load a set of work package ids into the states, regardless of them being loaded
   * @param workPackageIds
   */
  protected load(id:string) {
    return new Promise((resolve, reject) => {
      this.relationsDm
        .load(id)
        .then(elements => {
          this.mergeIntoStates(elements);
          resolve();
        })
        .catch((error) => reject(error));
    });
  }

  protected loadAll(ids:string[]) {
    const deferred = this.$q.defer<undefined>();

    this.relationsDm
      .loadInvolved(ids)
      .then((elements:RelationResource[]) => {
        this.mergeIntoStates(elements);
        this.initializeEmpty(ids);
        deferred.resolve();
      });

    return deferred.promise;
  }

  /**
   * Remove the given relation.
   */
  public removeRelation(relation:RelationResourceInterface) {
    return relation.delete().then(() => {
      _.each(relation.ids, (member:string) => {
        const state = this.multiState.get(member);
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
    const state = this.multiState.get(workPackageId);
    let relationsToInsert = _.keyBy(newRelations, r => r.id);
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

  private initializeEmpty(ids:string[]) {
    ids.forEach(id => {
      const state = this.multiState.get(id);
      if (state.isPristine()) {
        state.putValue({});
      }
    });
  }

}

opServicesModule.service('wpRelations', WorkPackageRelationsService);
