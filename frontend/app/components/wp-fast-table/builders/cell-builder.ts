import {WorkPackageResource} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {DisplayField} from './../../wp-display/wp-display-field/wp-display-field.module';
import {WorkPackageDisplayFieldService} from './../../wp-display/wp-display-field/wp-display-field.service';
import {injectorBridge} from '../../angular/angular-injector-bridge.functions';
export const tdClassName = 'wp-table--cell-td';
export const editableClassName = '-editable';
export const requiredClassName = '-required';
export const readOnlyClassName = '-read-only';
export const placeholderClassName = '-placeholder';
export const cellClassName = 'wp-table--cell-span';
export const editCellContainer = 'wp-table--cell-container';
export const wpCellTdClassName = 'wp-table--cell-td';
export const cellEmptyPlaceholder = '-';

export class CellBuilder {

  public wpDisplayField:WorkPackageDisplayFieldService;

  constructor() {
    injectorBridge(this);
  }

  public build(workPackage:WorkPackageResource, attribute:string) {
    const name = this.correctDateAttribute(workPackage, attribute);
    const td = document.createElement('td');
    td.classList.add(tdClassName, wpCellTdClassName, name);
    const container = document.createElement('span');
    container.classList.add(editCellContainer);
    const displayElement = this.buildDisplayElement(workPackage, name);

    container.appendChild(displayElement);
    td.appendChild(container);

    return td;
  }

  public refresh(container:HTMLElement, workPackage:WorkPackageResource, attribute:string) {
    const name = this.correctDateAttribute(workPackage, attribute);
    const span = this.buildDisplayElement(workPackage, name);

    container.innerHTML = '';
    container.appendChild(span);
  }

  private buildDisplayElement(workPackage:WorkPackageResource, name:string):HTMLElement {
    const fieldSchema = workPackage.schema[name];
    const span = document.createElement('span');
    span.classList.add(cellClassName, 'inplace-edit', 'wp-edit-field', name);
    span.dataset['fieldName'] = name;

    // Make span tabbable unless it's an id field
    span.setAttribute('tabindex', name === 'id' ? '-1' : '0');

    if (!fieldSchema) {
      return span;
    }

    const field = this.wpDisplayField.getField(workPackage, name, fieldSchema) as DisplayField;
    let text;

    if (field.writable && workPackage.isEditable) {
      span.classList.add(editableClassName);
    } else {
      span.classList.add(readOnlyClassName);
    }

    if (fieldSchema.required) {
      span.classList.add(requiredClassName);
    }

    if (field.isEmpty()) {
      span.classList.add(placeholderClassName);
      text = cellEmptyPlaceholder;
    } else {
      text = field.valueString;
    }

    field.render(span, text);
    return span;
  }

  /**
   * Milestones should display the 'date' attribute for start and due dates
   */
  private correctDateAttribute(workPackage:WorkPackageResource, name:string):string {
    if (workPackage.isMilestone && (name === 'dueDate' || name === 'startDate')) {
      return 'date';
    }

    return name;
  }
}

CellBuilder.$inject = ['wpDisplayField'];
