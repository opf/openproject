import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageChangeset} from './work-package-changeset';
import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {DisplayFieldContext, DisplayFieldService} from "core-app/modules/fields/display/display-field.service";
import {DisplayField} from "core-app/modules/fields/display/display-field.module";
import {MultipleLinesStringObjectsDisplayField} from "core-app/modules/fields/display/field-types/wp-display-multiple-lines-string-objects-field.module";
import {ProgressTextDisplayField} from "core-app/modules/fields/display/field-types/wp-display-progress-text-field.module";

export const editableClassName = '-editable';
export const requiredClassName = '-required';
export const readOnlyClassName = '-read-only';
export const placeholderClassName = '-placeholder';
export const cellClassName = 'wp-table--cell-span';
export const displayClassName = 'wp-edit-field--display-field';
export const editFieldContainerClass = 'wp-edit-field--container';
export const cellEmptyPlaceholder = '-';

export class DisplayFieldRenderer {

  readonly displayFieldService:DisplayFieldService = this.injector.get(DisplayFieldService);
  readonly I18n:I18nService = this.injector.get(I18nService);

  constructor(public readonly injector:Injector,
              public readonly container:'table' | 'single-view' | 'timeline',
              public readonly options:{ [key:string]: any } = {}) {
  }

  public render(workPackage:WorkPackageResource,
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

  public renderFieldValue(workPackage:WorkPackageResource,
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

  public getField(workPackage:WorkPackageResource,
                  fieldSchema:IFieldSchema,
                  name:string,
                  changeset:WorkPackageChangeset|null):DisplayField {
    const field = this.getFieldForCurrentContext(workPackage, fieldSchema, name);
    field.changeset = changeset;

    return field;
  }

  private getFieldForCurrentContext(workPackage:WorkPackageResource, fieldSchema:IFieldSchema, name:string):DisplayField {
    const context:DisplayFieldContext = { container: this.container, options: this.options };

    // We handle multi value fields differently in the single view context
    const isMultiLinesField = ['[]CustomOption', '[]User'].indexOf(fieldSchema.type) >= 0;
    if (this.container === 'single-view' && isMultiLinesField) {
      return new MultipleLinesStringObjectsDisplayField(workPackage, name, fieldSchema, context) as DisplayField;
    }

    // We handle progress differently in the timeline
    if (this.container === 'timeline' && name === 'percentageDone') {
      return new ProgressTextDisplayField(workPackage, name, fieldSchema, context);
    }

    return this.displayFieldService.getField(workPackage, name, fieldSchema, context);
  }

  private getText(field:DisplayField, placeholder:string):string {
    if (field.isEmpty()) {
      return placeholder;
    } else {
      return field.valueString;
    }
  }

  private setSpanAttributes(span:HTMLElement, field:DisplayField, name:string, workPackage:WorkPackageResource):void {
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

    if (field.writable && workPackage.isAttributeEditable(field.name)) {
      span.classList.add(editableClassName);
      span.setAttribute('role', 'button');
    } else {
      span.classList.add(readOnlyClassName);
    }
  }

  private getAriaLabel(field:DisplayField, workPackage:WorkPackageResource):string {
    let titleContent;
    let labelContent = this.getLabelContent(field);

    if (field.isFormattable && !field.isEmpty()) {
      try {
        titleContent = _.escape(jQuery(`<div>${labelContent}</div>`).text());
      } catch (e) {
        console.error("Failed to parse formattable labelContent");
        titleContent = "Label for " + field.displayName;
      }

    } else {
      titleContent = labelContent;
    }

    if (field.writable && workPackage.isAttributeEditable(field.name)) {
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
