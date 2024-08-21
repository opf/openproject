import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { multiInput, MultiInputState, StatesGroup } from '@openproject/reactivestates';
import { Injectable } from '@angular/core';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { StateCacheService } from 'core-app/core/apiv3/cache/state-cache.service';
import {
  firstValueFrom,
  Observable,
} from 'rxjs';
import { map, take } from 'rxjs/operators';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

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
  constructor(
    private PathHelper:PathHelperService,
    private apiV3Service:ApiV3Service,
    private halResource:HalResourceService,
    readonly turboRequests:TurboRequestsService,
  ) {
    super(new RelationStateGroup().relations);
  }

  /**
   * Require the value to be loaded either when forced or the value is stale
   * according to the cache interval specified for this service.
   *
   * Returns a single promise to one loaded value
   *
   * @param id The state to require
   * @param force Load the value anyway.
   */
  public require(id:string, force = false):Promise<RelationsStateValue> {
    return firstValueFrom(this.requireAndStream(id, force));
  }

  /**
   * Require the value to be loaded either when forced or the value is stale
   * according to the cache interval specified for this service.
   *
   * Returns an observable to the values stream of the state.
   *
   * @param id The state to require
   * @param force Load the value anyway.
   */
  public requireAndStream(id:string, force = false):Observable<RelationsStateValue> {
    // Refresh when stale or being forced
    if (this.stale(id) || force) {
      this.clearAndLoad(
        id,
        this.load(id),
      );
    }

    return this.state(id).values$();
  }

  /**
   * Load a set of work package ids into the states, regardless of them being loaded
   * @param workPackageIds
   */
  protected load(id:string):Observable<RelationsStateValue> {
    return this
      .apiV3Service
      .work_packages
      .id(id)
      .relations
      .get()
      .pipe(
        map((collection) => this.relationsStateValue(id, collection.elements)),
      );
  }

  public requireAll(ids:string[]):Promise<void> {
    return new Promise<undefined>((resolve, reject) => {
      this
        .apiV3Service
        .relations
        .loadInvolved(ids)
        .toPromise()
        .then((elements:RelationResource[]) => {
          this.clearSome(...ids);
          this.accumulateRelationsFromInvolved(ids, elements);
          resolve(undefined);
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
      return denormalized.target.id === to.id
        && denormalized.relationType === type;
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
        from: { href: from.href },
        to: { href: to.href },
      },
      type,
    };

    return this.updateRelation(relation, params);
  }

  public updateRelation(relation:RelationResource, params:{ [key:string]:any }) {
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
        from: { href: this.apiV3Service.work_packages.id(fromId).toString() },
        to: { href: this.apiV3Service.work_packages.id(relatedWpId).toString() },
      },
      type: relationType,
    };

    const path = this.apiV3Service.work_packages.id(fromId).relations.toString();
    return this.halResource
      .post<RelationResource>(path, params)
      .toPromise()
      .then((relation:RelationResource) => {
        this.insertIntoStates(relation);
        return relation;
      });
  }

  public updateCounter(workPackage:WorkPackageResource) {
    if (workPackage.id) {
      const url = this.PathHelper.workPackageUpdateCounterPath(workPackage.id, 'relations');
      void this.turboRequests.request(url);
    }
  }

  /**
   * Merges a single relation
   * @param relation
   */
  private insertIntoStates(relation:RelationResource) {
    _.values(relation.ids).forEach((wpId) => {
      this.multiState.get(wpId).doModify((value:RelationsStateValue) => {
        value[relation.id!] = relation;
        return value;
      }, () => {
        const value:RelationsStateValue = {};
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
    _.values(relation.ids).forEach((wpId) => {
      this.multiState.get(wpId).doModify((value:RelationsStateValue) => {
        delete value[relation.id!];
        return value;
      }, () => ({}));
    });
  }

  /**
   * Given a set of complete relations for this work package,
   * returns the RelationsStateValue
   *
   * @param wpId The wpId the relations belong to
   * @param relations The relation resource array.
   */
  private relationsStateValue(wpId:string, relations:RelationResource[]):RelationsStateValue {
    return _.keyBy(relations, (r) => r.id!);
  }

  /**
   *
   * We don't know how many values we're getting for a single work package
   * when we use the involved filter.
   *
   * We need to group relevant relations for work packages based on their to/from filter.
   */
  private accumulateRelationsFromInvolved(involved:string[], relations:RelationResource[]) {
    involved.forEach((wpId) => {
      const relevant = relations.filter((r) => r.isInvolved(wpId));
      const value = this.relationsStateValue(wpId, relevant);

      this.updateValue(wpId, value);
    });
  }
}
