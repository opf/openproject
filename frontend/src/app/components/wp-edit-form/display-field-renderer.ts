import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {DisplayFieldContext, DisplayFieldService} from "core-app/modules/fields/display/display-field.service";
import {DisplayField} from "core-app/modules/fields/display/display-field.module";
import {MultipleLinesStringObjectsDisplayField} from "core-app/modules/fields/display/field-types/multiple-lines-string-objects-display-field.module";
import {ProgressTextDisplayField} from "core-app/modules/fields/display/field-types/progress-text-display-field.module";
import {MultipleLinesUserFieldModule} from "core-app/modules/fields/display/field-types/multiple-lines-user-display-field.module";
import {ResourceChangeset} from "core-app/modules/fields/changeset/resource-changeset";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {CombinedDateDisplayField} from "core-app/modules/fields/display/field-types/combined-date-display.field";

export const editableClassName = '-editable';
export const requiredClassName = '-required';
export const readOnlyClassName = '-read-only';
export const placeholderClassName = '-placeholder';
export const displayClassName = 'inline-edit--display-field';
export const editFieldContainerClass = 'inline-edit--container';
export const cellEmptyPlaceholder = '-';

export class DisplayFieldRenderer<T extends HalResource = HalResource> {

  @InjectField() displayFieldService:DisplayFieldService;
  @InjectField() I18n:I18nService;

  /** We cache the previously used fields to avoid reinitialization */
  private fieldCache:{ [key:string]:DisplayField } = {};

  constructor(public readonly injector:Injector,
              public readonly container:'table'|'single-view'|'timeline',
              public readonly options:{ [key:string]:any } = {}) {
  }

  public render(resource:T,
                name:string,
                change:ResourceChangeset<T>|null,
                placeholder?:string):HTMLSpanElement {

    const [field, span] = this.renderFieldValue(resource, name, change, placeholder);

    if (field === null) {
      return span;
    }

    this.setSpanAttributes(span, field, name, resource);

    return span;
  }

  public renderFieldValue(resource:T,
                          name:string,
                          change:ResourceChangeset<T>|null,
                          placeholder?:string):[DisplayField|null, HTMLSpanElement] {
    const span = document.createElement('span');
    const schemaName = this.getSchemaName(resource, change, name);
    const fieldSchema = resource.schema[schemaName];

    // If the resource does not have that field, return an empty
    // span (e.g., for the table).
    if (!fieldSchema) {
      return [null, span];
    }

    const field = this.getField(resource, fieldSchema, schemaName, change);
    field.render(span, this.getText(field, fieldSchema, placeholder), fieldSchema.options);

    const title = field.title;
    if (title) {
      span.setAttribute('title', title);
    }
    span.setAttribute('aria-label', this.getAriaLabel(field, resource));

    return [field, span];
  }

  public getField(resource:T,
                  fieldSchema:IFieldSchema,
                  name:string,
                  change:ResourceChangeset<T>|null):DisplayField {
    let field = this.fieldCache[name];

    if (!field) {
      field = this.fieldCache[name] = this.getFieldForCurrentContext(resource, name, fieldSchema);
    }

    field.apply(resource, fieldSchema);
    field.activeChange = change;

    return field;
  }

  private getFieldForCurrentContext(resource:T, name:string, fieldSchema:IFieldSchema):DisplayField {
    const context:DisplayFieldContext = {container: this.container, injector: this.injector, options: this.options};

    // We handle multi value fields differently in the single view context
    const isCustomMultiLinesField = ['[]CustomOption'].indexOf(fieldSchema.type) >= 0;
    if (this.container === 'single-view' && isCustomMultiLinesField) {
      return new MultipleLinesStringObjectsDisplayField(name, context) as DisplayField;
    }
    const isUserMultiLinesField = ['[]User'].indexOf(fieldSchema.type) >= 0;
    if (this.container === 'single-view' && isUserMultiLinesField) {
      return new MultipleLinesUserFieldModule(name, context) as DisplayField;
    }

    // In the single view, start and end date are shown in a combined date field
    if (this.container === 'single-view' && (name === 'startDate')) {
      return new CombinedDateDisplayField(name, context) as DisplayField;
    }

    // We handle progress differently in the timeline
    if (this.container === 'timeline' && name === 'percentageDone') {
      return new ProgressTextDisplayField(name, context);
    }

    return this.displayFieldService.getField(resource, name, fieldSchema, context);
  }

  private getText(field:DisplayField, fieldSchema:IFieldSchema, placeholder?:string):string {
    if (field.isEmpty()) {
      return placeholder || this.getDefaultPlaceholder(fieldSchema);
    } else {
      return field.valueString;
    }
  }

  private setSpanAttributes(span:HTMLElement, field:DisplayField, name:string, resource:T):void {
    span.classList.add(displayClassName, name);
    span.dataset['fieldName'] = name;

    // Make span tabbable unless it's an id field
    span.setAttribute('tabindex', name === 'id' ? '-1' : '0');

    if (field.required) {
      span.classList.add(requiredClassName);
    }

    if (field.isEmpty()) {
      span.classList.add(placeholderClassName);
    }

    if (field.writable) {
      span.classList.add(editableClassName);
      span.setAttribute('role', 'button');
    } else {
      span.classList.add(readOnlyClassName);
    }
  }

  private getAriaLabel(field:DisplayField, resource:T):string {
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

    if (field.writable && resource.isAttributeEditable(field.name)) {
      return this.I18n.t('js.inplace.button_edit', {attribute: `${field.displayName} ${titleContent}`});
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

  /**
   * Get the schema name from either the changeset, the resource (if available) or
   * return the attribute itself.
   *
   * @param resource
   * @param change
   * @param name
   */
  private getSchemaName(resource:T, change:ResourceChangeset<T>|null, name:string) {
    if (change) {
      return change.getSchemaName(name);
    }

    if (!!resource.getSchemaName) {
      return resource.getSchemaName(name);
    }

    return name;
  }

  private getDefaultPlaceholder(fieldSchema:IFieldSchema):string {
    if (fieldSchema.type === 'Formattable') {
      return this.I18n.t('js.work_packages.placeholders.formattable', {name: fieldSchema.name});
    }

    return cellEmptyPlaceholder;
  }
}
