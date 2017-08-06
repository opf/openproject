import {$injectFields} from '../angular/angular-injector-bridge.functions';
import {WorkPackageDisplayFieldService} from '../wp-display/wp-display-field/wp-display-field.service';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {DisplayField} from '../wp-display/wp-display-field/wp-display-field.module';
import {MultipleLinesStringObjectsDisplayField} from '../wp-display/field-types/wp-display-multiple-lines-string-objects-field.module';
import {HalResource} from '../api/api-v3/hal-resources/hal-resource.service';

export const editableClassName = '-editable';
export const requiredClassName = '-required';
export const readOnlyClassName = '-read-only';
export const placeholderClassName = '-placeholder';
export const cellClassName = 'wp-table--cell-span';
export const displayClassName = 'wp-edit-field--display-field';
export const editFieldContainerClass = 'wp-edit-field--container';
export const cellEmptyPlaceholder = '-';

export class DisplayFieldRenderer {

  public wpDisplayField:WorkPackageDisplayFieldService;
  public I18n:op.I18n;

  constructor(public context:'table' | 'single-view') {
    $injectFields(this, 'wpDisplayField', 'I18n');
  }

  public render(workPackage:WorkPackageResourceInterface, name:string, placeholder = cellEmptyPlaceholder):HTMLSpanElement {
    const span = document.createElement('span');
    const schemaName = workPackage.getSchemaName(name);
    const fieldSchema = workPackage.schema[schemaName];

    // If the work package does not have that field, return an empty
    // span (e.g., for the table).
    if (!fieldSchema) {
      return span;
    }

    const field = this.getField(workPackage, fieldSchema, schemaName);

    this.setSpanAttributes(span, field, name, workPackage);

    field.render(span, this.getText(field, placeholder));
    span.setAttribute('title', this.getLabel(field, workPackage));
    span.setAttribute('aria-label', this.getAriaLabel(field, workPackage));

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

  private getText(field:DisplayField, placeholder:string):string {
    if (field.isEmpty()) {
      return placeholder;
    } else {
      return field.valueString;
    }
  }

  private setSpanAttributes(span:HTMLElement, field:DisplayField, name:string, workPackage:WorkPackageResourceInterface):void {
    span.classList.add(cellClassName, displayClassName, 'inplace-edit', 'wp-edit-field', name);
    span.dataset['fieldName'] = name;

    // Make span tabbable unless it's an id field
    span.setAttribute('tabindex', name === 'id' ? '-1' : '0');

    if (field.required) {
      span.classList.add(requiredClassName);
    }

    if (field.isEmpty()) {
      span.classList.add(placeholderClassName);
    }

    if (field.writable && workPackage.isEditable) {
      span.classList.add(editableClassName);
      span.setAttribute('role', 'button');
    } else {
      span.classList.add(readOnlyClassName);
    }
  }

  private getLabel(field:DisplayField, workPackage:WorkPackageResourceInterface):string {
    if (field.writable && workPackage.isEditable) {
      return this.I18n.t('js.inplace.button_edit', { attribute: `${field.displayName}` });
    } else {
      return field.displayName;
    }
  }

  private getAriaLabel(field:DisplayField, workPackage:WorkPackageResourceInterface):string {
    let titleContent;
    let labelContent = this.getLabelContent(field);

    if (field.isFormattable && !field.isEmpty()) {
      titleContent = angular.element(labelContent).text();

    } else {
      titleContent = labelContent;
    }

    if (field.writable && workPackage.isEditable) {
      return this.I18n.t('js.inplace.button_edit', { attribute: `${field.displayName} ${titleContent}` });
    } else {
      return `${field.displayName} ${titleContent}`;
    }
  }

  private getLabelContent(field:DisplayField):string {
    if (field.isEmpty()) {
      return this.I18n.t('js.inplace.null_value_label');
    } else {
      return field.valueString;
    }
  }
}
