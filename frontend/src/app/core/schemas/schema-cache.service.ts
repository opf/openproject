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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { State } from '@openproject/reactivestates';
import { Injectable, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { StateCacheService } from 'core-app/core/apiv3/cache/state-cache.service';
import {
  concat,
  defer,
  EMPTY,
  firstValueFrom,
  fromEvent,
  Observable,
  ReplaySubject,
  throwError,
} from 'rxjs';
import {
  catchError,
  filter,
  finalize,
  ignoreElements,
  share,
  take,
  tap,
} from 'rxjs/operators';
import { States } from 'core-app/core/states/states.service';
import { ISchemaProxy, SchemaProxy } from 'core-app/features/hal/schemas/schema-proxy';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageSchemaProxy } from 'core-app/features/hal/schemas/work-package-schema-proxy';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';

export const fallbackSchemaId = '__fallback';

@Injectable()
export class SchemaCacheService extends StateCacheService<SchemaResource> {
  readonly states:States;
  readonly halResourceService = inject(HalResourceService);

  fallbackSchema = this.halResourceService.createHalResourceOfClass<SchemaResource>(SchemaResource, {}, true);

  private readonly expired = new Set<string>();

  private readonly writes = new Map<string, number>();

  private readonly loads = new Map<string, { generation:number, done:Observable<never> }>();

  private visitGeneration = 0;

  constructor() {
    const states = inject(States);

    super(states.schemas);
    this.states = states;

    this.putValue(fallbackSchemaId, this.fallbackSchema);

    this.multiState
      .observeChange()
      .pipe(
        filter(([, value]) => value !== undefined),
        takeUntilDestroyed(),
      )
      .subscribe(([id]) => {
        this.expired.delete(id);
        this.writes.set(id, (this.writes.get(id) ?? 0) + 1);
      });

    fromEvent(document, 'op:page-visit')
      .pipe(takeUntilDestroyed())
      .subscribe(() => this.expireAll());
  }

  public state(id:string|HalResource):State<SchemaResource> {
    return super.state(this.stateKey(id));
  }

  /**
   * Returns the schema of the provided resource.
   * This method assumes the schema is loaded and will fail if it is not.
   * @deprecated Assuming the schema to be loaded is deprecated. Rely on the states instead.
   * @param resource The HalResource for which the schema is to be returned
   * @return The schema for the HalResource
   */
  of(resource:HalResource):ISchemaProxy {
    const schema = this.state(resource).value!;

    return this.proxied(resource, schema);
  }

  proxied(resource:HalResource, schema:SchemaResource):ISchemaProxy {
    if (resource._type === 'WorkPackage') {
      return WorkPackageSchemaProxy.create(schema, resource);
    }

    return SchemaProxy.create(schema, resource);
  }

  public getSchemaHref(resource:HalResource):string|undefined {
    return (resource.$links.schema as CallableHalLink|undefined)?.href as string|undefined;
  }

  /**
   * Ensure the given schema identified by its href is currently loaded.
   * @param resource The resource with a schema property or a string to the schema href.
   * @return A promise with the loaded schema.
   */
  ensureLoaded(resource:HalResource|string):Promise<SchemaResource> {
    const href = resource instanceof HalResource ? this.getSchemaHref(resource) : resource;
    return firstValueFrom(this.requireAndStream(href || fallbackSchemaId));
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
  public requireAndStream(href:string, force = false):Observable<SchemaResource> {
    if (force || this.stale(href) || this.hasCurrentLoad(href)) {
      return this.afterLoad(href, force);
    }

    return this.state(href).values$();
  }

  public override stale(href:string):boolean {
    if (href === fallbackSchemaId || this.hasCurrentLoad(href)) {
      return false;
    }

    const state = this.state(href);

    return !state.hasValue() || state.isValueOlderThan(this.cacheDurationInMs) || this.expired.has(href);
  }

  private expireAll():void {
    this.visitGeneration += 1;

    Object
      .entries(this.multiState.getValueOr({}))
      .filter(([id, state]) => id !== fallbackSchemaId && state.hasValue())
      .forEach(([id]) => this.expired.add(id));
  }

  private hasCurrentLoad(href:string):boolean {
    return this.loads.get(href)?.generation === this.visitGeneration;
  }

  private afterLoad(href:string, force:boolean):Observable<SchemaResource> {
    const generation = this.visitGeneration;
    const state = this.state(href);

    return concat(
      this.sharedLoad(href, force).pipe(
        catchError((error:unknown) => {
          if (state.hasValue() || generation !== this.visitGeneration) {
            return EMPTY;
          }

          return throwError(() => error);
        }),
      ),
      defer(() => (generation === this.visitGeneration
        ? state.values$()
        : this.requireAndStream(href))),
    );
  }

  private sharedLoad(href:string, force:boolean):Observable<never> {
    const pending = this.loads.get(href);
    if (!force && pending?.generation === this.visitGeneration) {
      return pending.done;
    }

    const generation = this.visitGeneration;
    const writes = this.writes.get(href) ?? 0;
    const done = this.load(href).pipe(
      tap((schema:SchemaResource) => {
        if (generation === this.visitGeneration && writes === (this.writes.get(href) ?? 0)) {
          this.putValue(href, schema);
        }
      }),
      ignoreElements(),
      finalize(() => {
        if (this.loads.get(href)?.done === done) {
          this.loads.delete(href);
        }
      }),
      share({
        connector: () => new ReplaySubject<never>(1),
        resetOnError: false,
        resetOnComplete: false,
        resetOnRefCountZero: false,
      }),
    );

    this.loads.set(href, { generation, done });
    done.subscribe({ error: () => undefined });

    return done;
  }

  /**
   * Load the associated schema for the given work package, if needed.
   */
  protected load(href:string):Observable<SchemaResource> {
    return this
      .halResourceService
      .get<SchemaResource>(href)
      .pipe(
        take(1),
      );
  }

  protected loadAll(hrefs:string[]):Promise<unknown> {
    return Promise.all(hrefs.map((href) => this.load(href)));
  }

  /**
   * Places the schema in the schema state of the resource.
   * @param resource The resource for which the schema is to be updated
   * @param schema
   */
  update(resource:HalResource, schema:SchemaResource) {
    this.multiState.get(this.stateKey(resource)).putValue(schema);
  }

  private stateKey(id:string|HalResource):string {
    if (id instanceof HalResource) {
      return this.getSchemaHref(id) || fallbackSchemaId;
    }

    return id;
  }
}
