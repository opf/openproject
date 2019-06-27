import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {
  DisplayFieldRenderer,
  editFieldContainerClass
} from '../../wp-edit-form/display-field-renderer';
import {Injector} from '@angular/core';
export const tdClassName = 'wp-table--cell-td';
export const editCellContainer = 'wp-table--cell-container';
export const wpCellTdClassName = 'wp-table--cell-td';

export class CellBuilder {

  private fieldRenderer = new DisplayFieldRenderer(this.injector, 'table');

  constructor(public injector:Injector) {
  }

  public build(workPackage:WorkPackageResource, attribute:string) {
    const td = document.createElement('td');
    td.classList.add(tdClassName, wpCellTdClassName, editFieldContainerClass, attribute);

    if (attribute === 'subject') {
      td.classList.add('-max');
    }

    const displayElement = this.fieldRenderer.render(workPackage, attribute, null);
    displayElement.classList.add(editCellContainer);
    td.appendChild(displayElement);

    return td;
  }

  public refresh(container:HTMLElement, workPackage:WorkPackageResource, attribute:string) {
    const displayElement = this.fieldRenderer.render(workPackage, attribute, null);

    container.appendChild(displayElement);
    return displayElement;
  }
}
