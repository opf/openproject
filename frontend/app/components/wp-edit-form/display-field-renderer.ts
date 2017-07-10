import {$injectFields} from '../angular/angular-injector-bridge.functions';
import {WorkPackageDisplayFieldService} from '../wp-display/wp-display-field/wp-display-field.service';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {DisplayField} from '../wp-display/wp-display-field/wp-display-field.module';
import {MultipleLinesStringObjectsDisplayField} from '../wp-display/field-types/wp-display-multiple-lines-string-objects-field.module';

export const editableClassName = '-editable';
export const requiredClassName = '-required';
export const readOnlyClassName = '-read-only';
export const placeholderClassName = '-placeholder';
export const cellClassName = 'wp-table--cell-span';
export const cellEmptyPlaceholder = '-';

export class DisplayFieldRenderer {

  public wpDisplayField:WorkPackageDisplayFieldService;

  constructor(public context:'table' | 'single-view') {
    $injectFields(this, 'wpDisplayField');
  }

  public render(workPackage:WorkPackageResourceInterface, attribute:string, placeholder = cellEmptyPlaceholder):HTMLSpanElement {
    const name = this.correctDateAttribute(workPackage, attribute);
    const span = document.createElement('span');
    const fieldSchema = workPackage.schema[name];

    // If the work package does not have that field, return an empty
    // span (e.g., for the table).
    if (!fieldSchema) {
      return span;
    }

    const field = this.getField(workPackage, fieldSchema, name);

    span.classList.add(cellClassName, 'inplace-edit', 'wp-edit-field', name);
    span.dataset['fieldName'] = name;

    // Make span tabbable unless it's an id field
    span.setAttribute('tabindex', name === 'id' ? '-1' : '0');

    let text;

    if (field.writable && workPackage.isEditable) {
      span.classList.add(editableClassName);
      span.setAttribute('role', 'button');
    } else {
      span.classList.add(readOnlyClassName);
    }

    if (field.required) {
      span.classList.add(requiredClassName);
    }

    if (field.isEmpty()) {
      span.classList.add(placeholderClassName);
      text = placeholder;
    } else {
      text = field.valueString;
    }

    field.render(span, text);
    return span;
  }

  public getField(workPackage:WorkPackageResourceInterface, fieldSchema:op.FieldSchema, name:string):DisplayField {
    // We handle multi value fields differently in the single view context
    const isMultiLinesField = ['[]CustomOption', '[]User'].indexOf(fieldSchema.type) >= 0;
    if (this.context === 'single-view' && isMultiLinesField) {
      return new MultipleLinesStringObjectsDisplayField(workPackage, name, fieldSchema);
    }

    return this.wpDisplayField.getField(workPackage, name, fieldSchema) as DisplayField;
  }

  /**
   * Milestones should display the 'date' attribute for start and due dates
   */
  public correctDateAttribute(workPackage:WorkPackageResourceInterface, name:string):string {
    if (workPackage.isMilestone && (name === 'dueDate' || name === 'startDate')) {
      return 'date';
    }

    return name;
  }
}
