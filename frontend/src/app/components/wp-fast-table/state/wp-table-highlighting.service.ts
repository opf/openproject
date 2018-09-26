import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageQueryStateService, WorkPackageTableBaseService} from './wp-table-base.service';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {Injectable} from '@angular/core';
import {States} from 'core-components/states.service';
import {HighlightingMode} from "core-components/wp-fast-table/builders/highlighting/highlighting-mode.const";
import {DynamicCssService} from "../../../modules/common/dynamic-css/dynamic-css.service";
import {WorkPackageTableHighlight} from "core-components/wp-fast-table/wp-table-highlight";
import {BannersService} from "core-app/modules/common/enterprise/banners.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

@Injectable()
export class WorkPackageTableHighlightingService extends WorkPackageTableBaseService<WorkPackageTableHighlight> implements WorkPackageQueryStateService {
  public constructor(readonly states:States,
                     readonly Banners:BannersService,
                     readonly dynamicCssService:DynamicCssService,
                     readonly tableState:TableState) {
    super(tableState);
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

    // 2. Is selected attributes === undefined ?
    if (this.current.selectedAttributes === undefined) {
      return true;
    }

    // 3. Is name in selected attributes ?
    return !!_.find(this.current.selectedAttributes, (attr:HalResource) => attr.id === name);
  }

  public get state() {
    return this.tableState.highlighting;
  }

  public get current():WorkPackageTableHighlight {
    let value = this.state.getValueOr(new WorkPackageTableHighlight('inline'));
    return this.filteredValue(value);
  }

  public get isInline() {
    return this.current.mode === 'inline';
  }

  public get isDisabled() {
    return this.current.mode === 'none';
  }

  public update(value:WorkPackageTableHighlight) {
    super.update(this.filteredValue(value));

    // Load dynamic highlighting CSS if enabled
    if (!this.isDisabled) {
      this.dynamicCssService.requireHighlighting();
    }
  }

  public valueFromQuery(query:QueryResource):WorkPackageTableHighlight {
    return this.filteredValue(new WorkPackageTableHighlight(query.highlightingMode, query.highlightedAttributes));
  }

  public hasChanged(query:QueryResource) {
    return query.highlightingMode !== this.current.mode ||
      !_.isEqual(query.highlightedAttributes, this.current.selectedAttributes);
  }

  public applyToQuery(query:QueryResource):boolean {
    const current = this.current;
    query.highlightingMode = current.mode;

    if (current.selectedAttributes) {
      query.highlightedAttributes = current.selectedAttributes;
    }

    return false;
  }

  private filteredValue(value:WorkPackageTableHighlight):WorkPackageTableHighlight {
    this.Banners.conditional(() => value.mode = 'none');
    return value;
  }
}
