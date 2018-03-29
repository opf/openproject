import {Injectable, Injector} from '@angular/core';
import {
  OpTableActionFactory,
} from 'core-components/wp-table/table-actions/table-action';
import {OpDetailsTableAction} from 'core-components/wp-table/table-actions/actions/details-table-action';
import {OpContextMenuTableAction} from 'core-components/wp-table/table-actions/actions/context-menu-table-action';
import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';

@Injectable()
export class OpTableActionsService {

  constructor(private readonly injector:Injector) {
  }

  /**
   * Actions currently registered
   */
  private actions:OpTableActionFactory[] = [
    (injector, workPackage) => new OpDetailsTableAction(injector, workPackage),
    (injector, workPackage) => new OpContextMenuTableAction(injector, workPackage),
  ];

  /**
   * Replace the actions with a different set
   */
  public setActions(...actions:OpTableActionFactory[]) {
    this.actions = actions;
  }

  /**
   * Render actions for the given work package.
   * @param {WorkPackageResource} workPackage
   */
  public render(workPackage:WorkPackageResourceInterface):HTMLElement[] {
    return this.actions.map((factory) => factory(this.injector, workPackage).buildElement());
  }
}
