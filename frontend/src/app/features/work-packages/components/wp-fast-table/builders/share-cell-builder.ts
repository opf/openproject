import { Injector } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { QueryColumn } from '../../wp-query/query-column';
import { tdClassName } from './cell-builder';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';

export class ShareCellbuilder {
  @InjectField(IsolatedQuerySpace) isolatedQuerySpace:IsolatedQuerySpace;
  constructor(public readonly injector:Injector) {
  }

  public build(workPackage:WorkPackageResource, column:QueryColumn) {
    const td = document.createElement('td');
    td.classList.add(tdClassName, column.id);
    td.dataset.columnId = column.id;

console.log(this.isolatedQuerySpace.workPackageSharesCache.get(workPackage.id!).getValueOr([]));

    td.innerHTML = `Share ${this.isolatedQuerySpace.workPackageSharesCache.get(workPackage.id!).getValueOr([]).map((share) => share.user.name).join(', ')}`;

    return td;
  }
}
