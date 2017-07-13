import {WorkPackageResourceInterface} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {
  DisplayFieldRenderer,
  editFieldContainerClass
} from '../../wp-edit-form/display-field-renderer';
export const tdClassName = 'wp-table--cell-td';
export const editCellContainer = 'wp-table--cell-container';
export const wpCellTdClassName = 'wp-table--cell-td';

export class CellBuilder {

  private fieldRenderer = new DisplayFieldRenderer('table');

  public build(workPackage:WorkPackageResourceInterface, attribute:string) {
    const name = this.fieldRenderer.correctDateAttribute(workPackage, attribute);
    const td = document.createElement('td');
    td.classList.add(tdClassName, wpCellTdClassName, name);

    const container = document.createElement('span');
    container.classList.add(editCellContainer, editFieldContainerClass, name);
    const displayElement = this.fieldRenderer.render(workPackage, name);

    container.appendChild(displayElement);
    td.appendChild(container);

    return td;
  }

  public refresh(container:HTMLElement, workPackage:WorkPackageResourceInterface, attribute:string) {
    const name = this.fieldRenderer.correctDateAttribute(workPackage, attribute);
    const displayElement = this.fieldRenderer.render(workPackage, name);

    container.innerHTML = '';
    container.appendChild(displayElement);
  }
}
