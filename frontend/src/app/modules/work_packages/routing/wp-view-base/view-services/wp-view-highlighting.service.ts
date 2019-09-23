import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageQueryStateService} from './wp-view-base.service';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {Injectable} from '@angular/core';
import {States} from 'core-components/states.service';
import {BannersService} from "core-app/modules/common/enterprise/banners.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";
import {QuerySchemaResource} from "core-app/modules/hal/resources/query-schema-resource";
import {WorkPackageViewHighlight} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-table-highlight";

@Injectable()
export class WorkPackageViewHighlightingService extends WorkPackageQueryStateService<WorkPackageViewHighlight>{
  public constructor(readonly states:States,
                     readonly Banners:BannersService,
                     readonly querySpace:IsolatedQuerySpace) {
    super(querySpace);
  }

  initialize(query:QueryResource, results:WorkPackageCollectionResource, schema?:QuerySchemaResource) {
    super.initialize(query, results, schema);
  }

  /**
   * Decides whether we want to inline highlight the given field name.
   *
   * @param name A display field name such as 'status', 'priority'.
   */
  public shouldHighlightInline(name:string):boolean {
    // 1. Are we in inline mode or unable to render?
    if (!this.isInline || this.Banners.eeShowBanners) {
      return false;
    }

    // 2. Is selected attributes === undefined or empty Array?
    if (this.current.selectedAttributes === undefined || this.current.selectedAttributes === []) {
      return true;
    }

    // 3. Is name in selected attributes ?
    return !!_.find(this.current.selectedAttributes, (attr:HalResource) => attr.id === name);
  }

  public get current():WorkPackageViewHighlight {
    let value = this.lastUpdatedState.getValueOr({ mode: 'inline' } as WorkPackageViewHighlight);
    return this.filteredValue(value);
  }

  public get isInline() {
    return this.current.mode === 'inline';
  }

  public get isDisabled() {
    return this.current.mode === 'none';
  }

  public update(value:WorkPackageViewHighlight) {
    super.update(this.filteredValue(value));
  }

  public valueFromQuery(query:QueryResource):WorkPackageViewHighlight {
    const highlight = { mode: query.highlightingMode || 'inline', selectedAttributes: query.highlightedAttributes };
    return this.filteredValue(highlight);
  }

  public hasChanged(query:QueryResource) {
    return query.highlightingMode !== this.current.mode ||
      !_.isEqual(query.highlightedAttributes, this.current.selectedAttributes);
  }

  public applyToQuery(query:QueryResource):boolean {
    const current = this.current;
    query.highlightingMode = current.mode;

    query.highlightedAttributes = current.selectedAttributes;

    return false;
  }

  private filteredValue(value:WorkPackageViewHighlight):WorkPackageViewHighlight {
    if (_.isEmpty(value.selectedAttributes)) {
      value.selectedAttributes = undefined;
    }

    this.Banners.conditional(() => {
      value.mode = 'none';
      value.selectedAttributes = undefined;
    });

    return value;
  }
}
