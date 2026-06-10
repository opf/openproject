import { Injectable, Injector, inject } from '@angular/core';
import {
  OpTableActionFactory,
} from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { OpDetailsTableAction } from 'core-app/features/work-packages/components/wp-table/table-actions/actions/details-table-action';
import { OpContextMenuTableAction } from 'core-app/features/work-packages/components/wp-table/table-actions/actions/context-menu-table-action';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

@Injectable()
export class OpTableActionsService {
  private readonly injector = inject(Injector);


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
  public render(workPackage:WorkPackageResource):HTMLElement[] {
    const built = this.actions.map((factory) => factory(this.injector, workPackage).buildElement());
    return _.compact(built);
  }
}
