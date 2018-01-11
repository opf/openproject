import {ProgressTextDisplayField} from './../wp-display/field-types/wp-display-progress-text-field.module';
import {$injectFields} from '../angular/angular-injector-bridge.functions';
import {WorkPackageDisplayFieldService} from '../wp-display/wp-display-field/wp-display-field.service';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {DisplayField} from '../wp-display/wp-display-field/wp-display-field.module';
import {MultipleLinesStringObjectsDisplayField} from '../wp-display/field-types/wp-display-multiple-lines-string-objects-field.module';
import {WorkPackageChangeset} from './work-package-changeset';

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

  constructor(public context:'table' | 'single-view' | 'timeline') {
    $injectFields(this, 'wpDisplayField', 'I18n');
  }

  public render(workPackage:WorkPackageResourceInterface,
                name:string,
                changeset:WorkPackageChangeset|null,
                placeholder = cellEmptyPlaceholder):HTMLSpanElement {
    const [field, span] = this.renderFieldValue(workPackage, name, changeset, placeholder);

    if (field === null) {
      return span;
    }

    this.setSpanAttributes(span, field, name, workPackage);

    return span;
  }

  public renderFieldValue(workPackage:WorkPackageResourceInterface,
                          name:string,
                          changeset:WorkPackageChangeset|null,
                          placeholder = cellEmptyPlaceholder):[DisplayField|null, HTMLSpanElement] {
    const span = document.createElement('span');
    const schemaName = workPackage.getSchemaName(name);
    const fieldSchema = workPackage.schema[schemaName];

    // If the work package does not have that field, return an empty
    // span (e.g., for the table).
    if (!fieldSchema) {
      return [null, span];
    }

    const field = this.getField(workPackage, fieldSchema, schemaName, changeset);
    field.render(span, this.getText(field, placeholder));

    const title = field.title;
    if (title) {
      span.setAttribute('title', title);
    }
    span.setAttribute('aria-label', this.getAriaLabel(field, workPackage));

    return [field, span];
  }

  public getField(workPackage:WorkPackageResourceInterface,
                  fieldSchema:op.FieldSchema,
                  name:string,
                  changeset:WorkPackageChangeset|null):DisplayField {
    const field = this.getFieldForCurrentContext(workPackage, fieldSchema, name);
    field.changeset = changeset;

    return field;
  }

  private getFieldForCurrentContext(workPackage:WorkPackageResourceInterface, fieldSchema:op.FieldSchema, name:string) {

    // We handle multi value fields differently in the single view context
    const isMultiLinesField = ['[]CustomOption', '[]User'].indexOf(fieldSchema.type) >= 0;
    if (this.context === 'single-view' && isMultiLinesField) {
      return new MultipleLinesStringObjectsDisplayField(workPackage, name, fieldSchema) as DisplayField;
    }

    // We handle progress differently in the timeline
    if (this.context === 'timeline' && name === 'percentageDone') {
      return new ProgressTextDisplayField(workPackage, name, fieldSchema);
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

  private getAriaLabel(field:DisplayField, workPackage:WorkPackageResourceInterface):string {
    let titleContent;
    let labelContent = this.getLabelContent(field);

    if (field.isFormattable && !field.isEmpty()) {
      try {
        titleContent = _.escape(angular.element(`<div>${labelContent}</div>`).text());
      } catch(e) {
        console.error("Failed to parse formattable labelContent");
        titleContent = "Label for " + field.displayName;
      }

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
