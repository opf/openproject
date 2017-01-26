import {WorkPackageResource} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {DisplayField} from './../../wp-display/wp-display-field/wp-display-field.module';
import {WorkPackageDisplayFieldService} from './../../wp-display/wp-display-field/wp-display-field.service';
import {injectorBridge} from '../../angular/angular-injector-bridge.functions';
export const tdClassName = 'wp-table--cell-td';
export const editableClassName = '-editable';
export const requiredClassName = '-required';
export const placeholderClassName = '-placeholder';
export const cellClassName = 'wp-table--cell-span';
export const cellEmptyPlaceholder = '-';

export class CellBuilder {

  public wpDisplayField:WorkPackageDisplayFieldService;

  constructor() {
    injectorBridge(this);
  }

  public build(workPackage:WorkPackageResource, name:string) {
    let fieldSchema = workPackage.schema[name];

    let td = document.createElement('td');
    td.classList.add(tdClassName, name);
    let span = document.createElement('span');
    span.classList.add(cellClassName, name);
    span.dataset['fieldName'] = name;

    // Make span tabbable unless it's an id field
    span.setAttribute('tabindex', name === 'id' ? '-1' : '0');

    if (!fieldSchema) {
      // startDate / dueDate
      return td;
    }

    const field = <DisplayField> this.wpDisplayField.getField(workPackage, name, fieldSchema);

    let text;

    if (name === 'id') {
      td.classList.add('-short');
    }

    if (fieldSchema.writable) {
      span.classList.add(editableClassName);
    }

    if (fieldSchema.required) {
      span.classList.add(requiredClassName);
    }

    if (field.isEmpty()) {
      span.classList.add(placeholderClassName);
      text = cellEmptyPlaceholder;
    } else {
      text = field.valueString;
      span.setAttribute('aria-label', `${field.label} ${text}`);
    }

    field.render(span, text);
    td.appendChild(span);

    return td;
  }
}

CellBuilder.$inject = ['wpDisplayField'];
