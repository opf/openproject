import {multiInput, StatesGroup} from 'reactivestates';
import {
  RelationResource,
  RelationResourceInterface
} from '../api/api-v3/hal-resources/relation-resource.service';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {RelationsDmService} from '../api/api-v3/hal-resource-dms/relations-dm.service';
import {WorkPackageTableRefreshService} from '../wp-table/wp-table-refresh-request.service';
import {opServicesModule} from '../../angular-modules';
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
  protected load(id:string):Promise<RelationsStateValue> {
    return new Promise((resolve, reject) => {
      this.relationsDm
        .load(id)
        .then(elements => {
          this.updateRelationsStateTo(id, elements);
          resolve(this.state(id).value!);
        })
        .catch((error) => reject(error));
    });
  }

  protected loadAll(ids:string[]) {
    const deferred = this.$q.defer<undefined>();

    this.relationsDm
      .loadInvolved(ids)
      .then((elements:RelationResource[]) => {
        this.clearSome(...ids);
        this.accumulateRelationsFromInvolved(ids, elements);
        deferred.resolve();
      });

    return deferred.promise;
  }

  /**
   * Remove the given relation.
   */
  public removeRelation(relation:RelationResourceInterface) {
    return relation.delete().then(() => {
      this.removeFromStates(relation);
      this.wpTableRefresh.request(
        `Removing relation (${relation.ids.from} to ${relation.ids.to})`,
        true
      );
    });
  }

  /**
   * Update the given relation type, setting new values for from and to
   */
  public updateRelationType(from:WorkPackageResourceInterface, to:WorkPackageResourceInterface, relation:RelationResourceInterface, type:string) {
    const params = {
      _links: {
        from: {href: from.href},
        to: {href: to.href}
      },
      type: type
    };

    return this.updateRelation(relation, params);
  }

  public updateRelation(relation:RelationResourceInterface, params:{[key:string]: any}) {
    return relation.updateImmediately(params)
      .then((savedRelation:RelationResourceInterface) => {
        this.insertIntoStates(savedRelation);
        this.wpTableRefresh.request(
          `Updating relation (${relation.ids.from} to ${relation.ids.to})`,
          true
        );
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
      this.insertIntoStates(relation);
      this.wpTableRefresh.request(
        `Adding relation (${relation.ids.from} to ${relation.ids.to})`,
        true
      );
      return relation;
    });
  }

  /**
   * Merges a single relation
   * @param relation
   */
  private insertIntoStates(relation:RelationResource) {
    _.values(relation.ids).forEach(wpId => {
      this.multiState.get(wpId).doModify((value:RelationsStateValue) => {
        value[relation.id] = relation;
        return value;
      }, () => {
        let value:RelationsStateValue = {};
        value[relation.id] = relation;
        return value;
      });
    });
  }

  /**
   * Remove the given relation from the from/to states
   * @param relation
   */
  private removeFromStates(relation:RelationResource) {
    _.values(relation.ids).forEach(wpId => {
      this.multiState.get(wpId).doModify((value:RelationsStateValue) => {
        delete value[relation.id];
        return value;
      }, () => { return {}; });
    });
  }

  /**
   * Given a set of complete relations for this work packge, fill
   * the associated relations state
   *
   * @param wpId The wpId the relations belong to
   * @param relations The relation resource array.
   */
  private updateRelationsStateTo(wpId:string, relations:RelationResource[]) {
    const state = this.multiState.get(wpId);
    const relationsToInsert = _.keyBy(relations, r => r.id);

    state.putValue(relationsToInsert, "Overriding relations state.");
  }

  /**
   *
   * We don't know how many values we're getting for a single work package
   * when we use the involved filter.
   *
   * We need to group relevant relations for work packages based on their to/from filter.
   */
  private accumulateRelationsFromInvolved(involved:string[], relations:RelationResource[]) {
    involved.forEach(id => {
      const relevant = relations.filter(r => r.isInvolved(id));
      this.updateRelationsStateTo(id, relevant);
    });

  }

}

opServicesModule.service('wpRelations', WorkPackageRelationsService);
