import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageQueryStateService} from './wp-table-base.service';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {Injectable} from '@angular/core';
import {States} from 'core-components/states.service';
import {DynamicCssService} from "../../../modules/common/dynamic-css/dynamic-css.service";
import {WorkPackageTableHighlight} from "core-components/wp-fast-table/wp-table-highlight";
import {BannersService} from "core-app/modules/common/enterprise/banners.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

@Injectable()
export class WorkPackageTableHighlightingService extends WorkPackageQueryStateService<WorkPackageTableHighlight>{
  public constructor(readonly states:States,
                     readonly Banners:BannersService,
                     readonly dynamicCssService:DynamicCssService,
                     readonly querySpace:IsolatedQuerySpace) {
    super(querySpace);
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

  public get state() {
    return this.querySpace.highlighting;
  }

  public get current():WorkPackageTableHighlight {
    let value = this.state.getValueOr({ mode: 'inline' } as WorkPackageTableHighlight);
    return this.filteredValue(value);
  }

  public get isInline() {
    return this.current.mode === 'inline';
  }

  public get isDisabled() {
    return this.current.mode === 'none';
  }

  public update(value:WorkPackageTableHighlight) {
    if (_.isEmpty(value.selectedAttributes)) {
      value.selectedAttributes = undefined;
    }

    super.update(this.filteredValue(value));

    // Load dynamic highlighting CSS if enabled
    if (!this.isDisabled) {
      this.dynamicCssService.requireHighlighting();
    }
  }

  public valueFromQuery(query:QueryResource):WorkPackageTableHighlight {
    const highlight = { mode: query.highlightingMode || 'inline', highlightedAttributes: query.highlightedAttributes };
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

  private filteredValue(value:WorkPackageTableHighlight):WorkPackageTableHighlight {
    this.Banners.conditional(() => {
      value.mode = 'none';
      value.selectedAttributes = undefined;
    });
    return value;
  }
}
