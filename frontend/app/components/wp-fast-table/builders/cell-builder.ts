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
    const td = document.createElement('td');
    td.classList.add(tdClassName, wpCellTdClassName, attribute);

    const container = document.createElement('span');
    container.classList.add(editCellContainer, editFieldContainerClass, attribute);
    const displayElement = this.fieldRenderer.render(workPackage, attribute);

    container.appendChild(displayElement);
    td.appendChild(container);

    return td;
  }

  public refresh(container:HTMLElement, workPackage:WorkPackageResourceInterface, attribute:string) {
    const displayElement = this.fieldRenderer.render(workPackage, attribute);

    container.innerHTML = '';
    container.appendChild(displayElement);
  }
}
