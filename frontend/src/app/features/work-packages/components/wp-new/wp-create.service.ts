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
  Injectable,
  Injector,
} from '@angular/core';
import {
  firstValueFrom,
  Observable,
  Subject,
} from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HookService } from 'core-app/features/plugins/hook-service';
import {
  WorkPackageFilterValues,
} from 'core-app/features/work-packages/components/wp-edit-form/work-package-filter-values';
import {
  HalResourceEditingService,
  ResourceChangesetCommit,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { filter } from 'rxjs/operators';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import {
  HalResource,
  HalSource,
  HalSourceLink,
} from 'core-app/features/hal/resources/hal-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { AttachmentsResourceService } from 'core-app/core/state/attachments/attachments.service';
import { AttachmentCollectionResource } from 'core-app/features/hal/resources/attachment-collection-resource';

export const newWorkPackageHref = '/api/v3/work_packages/new';

@Injectable()
export class WorkPackageCreateService extends UntilDestroyedMixin {
  protected form:Promise<FormResource>|undefined;

  // Allow callbacks to happen on newly created work packages
  protected newWorkPackageCreatedSubject = new Subject<WorkPackageResource>();

  constructor(
    protected injector:Injector,
    protected hooks:HookService,
    protected apiV3Service:ApiV3Service,
    protected halResourceService:HalResourceService,
    protected querySpace:IsolatedQuerySpace,
    protected authorisationService:AuthorisationService,
    protected halEditing:HalResourceEditingService,
    protected schemaCache:SchemaCacheService,
    protected halEvents:HalEventsService,
    protected attachmentsService:AttachmentsResourceService,
  ) {
    super();

    this.halEditing
      .committedChanges
      .pipe(
        this.untilDestroyed(),
        filter((commit) => commit.resource._type === 'WorkPackage' && commit.wasNew),
      )
      .subscribe((commit:ResourceChangesetCommit<WorkPackageResource>) => {
        this.newWorkPackageCreated(commit.resource);
      });

    this.halEditing
      .changes$(newWorkPackageHref)
      .pipe(
        this.untilDestroyed(),
        filter((changeset) => !changeset),
      )
      .subscribe(() => {
        this.reset();
      });
  }

  protected newWorkPackageCreated(wp:WorkPackageResource):void {
    this.reset();
    this.newWorkPackageCreatedSubject.next(wp);
  }

  public onNewWorkPackage():Observable<WorkPackageResource> {
    return this.newWorkPackageCreatedSubject.asObservable();
  }

  public createNewWorkPackage(projectIdentifier:string|undefined|null, payload:HalSource):Promise<WorkPackageChangeset> {
    return this
      .apiV3Service
      .withOptionalProject(projectIdentifier)
      .work_packages
      .form
      .forPayload(payload)
      .toPromise()
      .then((form:FormResource) => this.fromCreateForm(form));
  }

  public fromCreateForm(form:FormResource):WorkPackageChangeset {
    const wp = this.initializeNewResource(form);

    const change = this.halEditing.edit<WorkPackageResource, WorkPackageChangeset>(wp, form);

    // Call work package initialization hook
    this.hooks.call('workPackageNewInitialization', change);

    return change;
  }

  public copyWorkPackage(copyFrom:WorkPackageChangeset):Promise<WorkPackageChangeset> {
    const request = copyFrom.pristineResource.$source;

    // Ideally we would make an empty request before to get the create schema (cannot use the update schema of the source changeset)
    // to get all the writable attributes and only send those.
    // But as this would require an additional request, we don't.
    return this
      .apiV3Service
      .work_packages
      .form
      .post(request)
      .toPromise()
      .then((form:FormResource) => {
        const changeset = this.fromCreateForm(form);

        return changeset;
      });
  }

  /**
   * Create a copy resource from other and the new work package form
   * @param form Work Package create form
   */
  private copyFrom(form:FormResource) {
    const wp = this.initializeNewResource(form);

    return this.halEditing.edit(wp, form);
  }

  public getEmptyForm(projectIdentifier:string|null|undefined):Promise<FormResource> {
    if (!this.form) {
      this.form = firstValueFrom(
        this
          .apiV3Service
          .withOptionalProject(projectIdentifier)
          .work_packages
          .form
          .post({}),
      );
    }

    return this.form;
  }

  public cancelCreation():void {
    this.halEditing.stopEditing({ href: newWorkPackageHref });
    this.reset();
  }

  public changesetUpdates$():Observable<ResourceChangeset> {
    return this
      .halEditing
      .state(newWorkPackageHref)
      .values$();
  }

  public createOrContinueWorkPackage(projectIdentifier:string|null|undefined, type?:number, defaults?:HalSource):Promise<WorkPackageChangeset> {
    let changePromise = this.continueExistingEdit(type);

    if (!changePromise) {
      changePromise = this.createNewWithDefaults(projectIdentifier, defaults);
    }

    return changePromise.then((change:WorkPackageChangeset) => {
      this.authorisationService.initModelAuth('work_package', change.pristineResource);
      this.halEditing.updateValue(newWorkPackageHref, change);
      this
        .apiV3Service
        .work_packages
        .cache
        .updateWorkPackage(change.pristineResource, true);

      return change;
    });
  }

  protected reset():void {
    this
      .apiV3Service
      .work_packages
      .cache
      .clearSome('new');

    this
      .attachmentsService
      .clear('new');

    this.form = undefined;
  }

  protected continueExistingEdit(type?:number):Promise<WorkPackageChangeset>|null {
    const change = this.halEditing.state(newWorkPackageHref).value as WorkPackageChangeset;
    if (change !== undefined) {
      const changeType = change.projectedResource.type;

      const hasChanges = !change.isEmpty();
      const typeEmpty = !changeType && !type;
      const typeMatches = type && changeType && idFromLink(changeType.href) === type.toString();

      if (hasChanges && (typeEmpty || typeMatches)) {
        return Promise.resolve(change);
      }
    }

    return null;
  }

  /**
   * Initializes a new work package. The work package is not yet persisted.
   * The properties of the work package are initialized from two sources:
   *  * The default values provided
   *  * The filter values that might exist in the query space
   *
   *  The first can be employed to e.g. provide the type or the parent of the work package.
   *  The later can be employed to create a work package that adheres to the filter values.
   *
   * @param projectIdentifier The project the work package is to be created in.
   * @param defaults Values the new work package should possess on creation.
   */
  protected createNewWithDefaults(projectIdentifier:string|null|undefined, defaults?:HalSource):Promise<WorkPackageChangeset> {
    return this
      .withFiltersPayload(projectIdentifier, defaults)
      .then((filterDefaults) => {
        const mergedPayload = _.merge({ _links: {} }, filterDefaults, defaults);

        return this.createNewWorkPackage(projectIdentifier, mergedPayload).then((change:WorkPackageChangeset) => {
          if (!change) {
            throw new Error('No new work package was created');
          }

          // We need to apply the defaults again (after them being applied in the form requests)
          // here as the initial form requests might have led to some default
          // values not being carried over. This can happen when custom fields not available in one type are filter values.
          // The defaults should be applied to the customFields only, hence we ignore the other filters.
          const ignoreFiltersFn = (id:string):boolean => /customField\d+/.exec(id) === null;
          this.defaultsFromFilters(change, defaults, ignoreFiltersFn);

          return change;
        });
      });
  }

  /**
   * Fetches all values of filters applicable to work as default values (e.g. assignee = 123).
   * If defaults already contain the type, that filter is ignored.
   *
   * The ignoring functionality could be generalized.
   *
   * @param object
   * @param defaults
   */
  private defaultsFromFilters(
    object:HalSource|WorkPackageChangeset,
    defaults?:HalSource,
    ignoreFiltersFn?:(id:string) => boolean,
  ):void {
    // Not using WorkPackageViewFiltersService here as the embedded table does not load the form
    // which will result in that service having empty current filters.
    const query = this.querySpace.query.value;

    if (query) {
      let except = defaults?._links ? Object.keys(defaults._links) : [];

      if (ignoreFiltersFn !== undefined) {
        except = except.concat(query.filters.map((f) => f.id).filter(ignoreFiltersFn));
      }

      new WorkPackageFilterValues(this.injector, query.filters, except)
        .applyDefaultsFromFilters(object);
    }
  }

  /**
   * Returns valid payload based on the filters active in the query space validated by the backend via a form
   * request. In case no filters are active, the (empty) filters payload is just passed through.
   *
   * If there are filters applied, we need the additional form request to turn the defaults of the filters into
   * a valid payload in the sense that all properties are at their correct place and are in the right format. That means
   * HalResources are in the _links section and follow the { href: some_link } format while simple properties stay on the
   * top level.
   */
  private withFiltersPayload(projectIdentifier:string|null|undefined, defaults?:HalSource):Promise<HalSource> {
    const fromFilter = { _links: {} };
    this.defaultsFromFilters(fromFilter, defaults);

    const filtersApplied = Object.keys(fromFilter).length > 1 || Object.keys(fromFilter._links).length > 0;

    if (filtersApplied) {
      return this
        .apiV3Service
        .withOptionalProject(projectIdentifier)
        .work_packages
        .form
        .forTypePayload(defaults || { _links: {} })
        .toPromise()
        .then((form:FormResource) => {
          this.toApiPayload(fromFilter, form.schema);
          return fromFilter;
        });
    }
    return Promise.resolve(fromFilter);
  }

  private toApiPayload(payload:HalSource, schema:SchemaResource) {
    const links:string[] = [];

    Object.keys(schema.$source).forEach((attribute) => {
      if (!['Integer',
        'Float',
        'Date',
        'DateTime',
        'Duration',
        'Formattable',
        'Boolean',
        'String',
        'Text',
        undefined].includes(schema.$source[attribute].type)) {
        links.push(attribute);
      }
    });

    links.forEach((attribute) => {
      const value = payload[attribute];
      if (value === undefined) {
        // nothing
      } else if (value instanceof HalResource) {
        payload._links[attribute] = { href: value.$links.self.href };
      } else if (!value) {
        payload._links[attribute] = { href: null };
      } else {
        payload._links[attribute] = value as unknown as HalSourceLink;
      }
      delete payload[attribute];
    });
  }

  /**
   * Assign values from the form for a newly created work package resource.
   * @param form
   */
  private initializeNewResource(form:FormResource) {
    const payload = form.payload.$plain() as object&{ _links:{ schema:{ href:string } } };

    // maintain the reference to the schema
    payload._links.schema = { href: 'new' };

    const wp = this.halResourceService.createHalResourceOfType<WorkPackageResource>('WorkPackage', payload);

    wp.$source.id = 'new';

    // Ensure type is set to identify the resource
    wp._type = 'WorkPackage';

    // Since the ID will change upon saving, keep track of the WP
    // with the actual creation date
    wp.__initialized_at = Date.now();

    // Set update link to form
    wp.update = wp.$links.update = form.$links.self;
    // Use POST /work_packages for saving link
    wp.updateImmediately = (data:object) => firstValueFrom(this.apiV3Service.work_packages.post(data));
    wp.$links.updateImmediately = (data:object) => firstValueFrom(this.apiV3Service.work_packages.post(data));

    if (form.schema.$links.attachments) {
      wp.$links.attachments = { elements: [] } as unknown as AttachmentCollectionResource;
    }

    // We need to provide the schema to the cache so that it is available in the html form to e.g. determine
    // the editability.
    // It would be better if the edit field could simply rely on the changeset if it exists.
    this.schemaCache.update(wp, form.schema);

    return wp;
  }
}
