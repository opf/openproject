import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageQueryStateService, WorkPackageTableBaseService} from './wp-table-base.service';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {Injectable} from '@angular/core';
import {States} from 'core-components/states.service';

export type HighlightingMode = 'status'|'priority'|'default'|'disabled';

@Injectable()
export class WorkPackageTableHighlightingService extends WorkPackageTableBaseService<HighlightingMode> implements WorkPackageQueryStateService {
  public constructor(readonly states:States,
                     readonly tableState:TableState) {
    super(tableState);
  }

  public get state() {
    return this.tableState.highlighting;
  }

  public get current() {
    return this.state.getValueOr('default');
  }

  public get isDefault() {
    return this.current === 'default';
  }

  public get isDisabled() {
    return this.current === 'disabled';
  }

  public update(value:HighlightingMode) {
    this.state.putValue(value);
  }

  public valueFromQuery(query:QueryResource):HighlightingMode|undefined {
    return 'default';
  }

  public hasChanged(query:QueryResource) {
    return false;
  }

  public applyToQuery(query:QueryResource) {
    return false;
  }
}
