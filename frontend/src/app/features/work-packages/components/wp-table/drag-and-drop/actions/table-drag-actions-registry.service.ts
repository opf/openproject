import { Injectable, Injector } from '@angular/core';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { TableDragActionService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-action.service';
import { HierarchyDragActionService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/hierarchy-drag-action.service';
import { GroupByDragActionService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/group-by-drag-action.service';

interface ITableDragActionService {
  new(querySpace:IsolatedQuerySpace, injector:Injector):TableDragActionService;
}

@Injectable()
export class TableDragActionsRegistryService {
  private register:ITableDragActionService[] = [
    HierarchyDragActionService,
    GroupByDragActionService,
  ];

  public add(service:ITableDragActionService) {
    this.register.push(service);
  }

  public get(injector:Injector):TableDragActionService {
    const querySpace = injector.get(IsolatedQuerySpace);

    const match = this.register
      .map((cls) => new cls(querySpace, injector))
      .find((instance) => instance.applies);

    return match || new TableDragActionService(querySpace, injector);
  }
}
