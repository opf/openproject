import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageQueryStateService, WorkPackageTableBaseService} from './wp-table-base.service';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {Injectable} from '@angular/core';
import {States} from 'core-components/states.service';
import {HighlightingMode} from "core-components/wp-fast-table/builders/highlighting/highlighting-mode.const";
import {DynamicCssService} from "../../../modules/common/dynamic-css/dynamic-css.service";
import {WorkPackageTableHighlight} from "core-components/wp-fast-table/wp-table-highlight";
import {BannersService} from "core-app/modules/common/enterprise/banners.service";

@Injectable()
export class WorkPackageTableHighlightingService extends WorkPackageTableBaseService<WorkPackageTableHighlight> implements WorkPackageQueryStateService {
  public constructor(readonly states:States,
                     readonly Banners:BannersService,
                     readonly dynamicCssService:DynamicCssService,
                     readonly tableState:TableState) {
    super(tableState);
  }

  public get state() {
    return this.tableState.highlighting;
  }

  public get current():WorkPackageTableHighlight {
    let value =  this.state.getValueOr(new WorkPackageTableHighlight('inline'));
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
