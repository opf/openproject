import {RelationsDmService} from 'core-app/modules/hal/dm-services/relations-dm.service';
import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {multiInput, MultiInputState, StatesGroup} from 'reactivestates';
import {StateCacheService} from '../states/state-cache.service';
import {Injectable} from "@angular/core";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";

export type RelationsStateValue = { [relationId:string]:RelationResource };

export class RelationStateGroup extends StatesGroup {
  name = 'WP-Relations';

  relations:MultiInputState<RelationsStateValue> = multiInput<RelationsStateValue>();

  constructor() {
    super();
    this.initializeMembers();
  }
}

@Injectable()
export class WorkPackageRelationsService extends StateCacheService<RelationsStateValue> {

  private relationStates:RelationStateGroup;

  /*@ngInject*/
  constructor(private relationsDm:RelationsDmService,
              private PathHelper:PathHelperService,
              private halResource:HalResourceService) {
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
    return new Promise<RelationsStateValue>((resolve, reject) => {
      this.relationsDm
        .load(id)
        .then(elements => {
          this.updateRelationsStateTo(id, elements);
          resolve(this.state(id).value!);
        })
        .catch(reject);
    });
  }

  protected loadAll(ids:string[]) {
    return new Promise<undefined>((resolve, reject) => {
      this.relationsDm
        .loadInvolved(ids)
        .then((elements:RelationResource[]) => {
          this.clearSome(...ids);
          this.accumulateRelationsFromInvolved(ids, elements);
          resolve();
        })
        .catch(reject);
    });
  }

  /**
   * Find a given relation by from, to and relation Type
   */
  public find(from:WorkPackageResource, to:WorkPackageResource, type:string):RelationResource|undefined {
    const relations:RelationsStateValue|undefined = this.state(from.id!).value;

    if (!relations) {
      return;
    }

    return _.find(relations, (relation:RelationResource) => {
      const denormalized = relation.denormalized(from);
      // Check that
      // 1. the denormalized relation points at "to"
      // 2. that the denormalized relation type matches.
      return denormalized.target.id === to.id &&
        denormalized.relationType === type;
    });
  }

  /**
   * Remove the given relation.
   */
  public removeRelation(relation:RelationResource) {
    return relation.delete().then(() => {
      this.removeFromStates(relation);
    });
  }

  /**
   * Update the given relation type, setting new values for from and to
   */
  public updateRelationType(from:WorkPackageResource, to:WorkPackageResource, relation:RelationResource, type:string) {
    const params = {
      _links: {
        from: {href: from.href},
        to: {href: to.href}
      },
      type: type
    };

    return this.updateRelation(relation, params);
  }

  public updateRelation(relation:RelationResource, params:{[key:string]:any}) {
    return relation.updateImmediately(params)
      .then((savedRelation:RelationResource) => {
        this.insertIntoStates(savedRelation);
        return savedRelation;
      });
  }

  public addCommonRelation(fromId:string,
                           relationType:string,
                           relatedWpId:string) {
    const params = {
      _links: {
        from: {href: this.PathHelper.api.v3.work_packages.id(fromId).toString() },
        to: {href: this.PathHelper.api.v3.work_packages.id(relatedWpId).toString() }
      },
      type: relationType
    };

    const path = this.PathHelper.api.v3.work_packages.id(fromId).relations.toString();
    return this.halResource
      .post<RelationResource>(path, params)
      .toPromise()
      .then((relation:RelationResource) => {
      this.insertIntoStates(relation);
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
        value[relation.id!] = relation;
        return value;
      }, () => {
        let value:RelationsStateValue = {};
        value[relation.id!] = relation;
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
        delete value[relation.id!];
        return value;
      }, () => {
        return {};
      });
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
    const relationsToInsert = _.keyBy(relations, r => r.id!);

    state.putValue(relationsToInsert, 'Overriding relations state.');
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
