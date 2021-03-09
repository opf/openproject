import { Injector } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { IFieldSchema } from "core-app/modules/fields/field.base";
import { DisplayFieldContext, DisplayFieldService } from "core-app/modules/fields/display/display-field.service";
import { DisplayField } from "core-app/modules/fields/display/display-field.module";
import { MultipleLinesCustomOptionsDisplayField } from "core-app/modules/fields/display/field-types/multiple-lines-custom-options-display-field.module";
import { ProgressTextDisplayField } from "core-app/modules/fields/display/field-types/progress-text-display-field.module";
import { MultipleLinesUserFieldModule } from "core-app/modules/fields/display/field-types/multiple-lines-user-display-field.module";
import { ResourceChangeset } from "core-app/modules/fields/changeset/resource-changeset";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";
import { SchemaResource } from "core-app/modules/hal/resources/schema-resource";
import { ISchemaProxy } from "core-app/modules/hal/schemas/schema-proxy";
import { HalResourceEditingService } from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import { DateDisplayField } from "core-app/modules/fields/display/field-types/date-display-field.module";

export const editableClassName = '-editable';
export const requiredClassName = '-required';
export const readOnlyClassName = '-read-only';
export const placeholderClassName = '-placeholder';
export const displayClassName = 'inline-edit--display-field';
export const editFieldContainerClass = 'inline-edit--container';
export const cellEmptyPlaceholder = '-';

export class DisplayFieldRenderer<T extends HalResource = HalResource> {

  @InjectField() displayFieldService:DisplayFieldService;
  @InjectField() schemaCache:SchemaCacheService;
  @InjectField() halEditing:HalResourceEditingService;
  @InjectField() I18n!:I18nService;

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

    this.setSpanAttributes(span, field, name, resource, change);

    return span;
  }

  public renderFieldValue(resource:T,
    requestedAttribute:string,
    change:ResourceChangeset<T>|null,
    placeholder?:string):[DisplayField|null, HTMLSpanElement] {
    const span = document.createElement('span');
    const schema = this.schema(resource, change);
    const attributeName = this.attributeName(requestedAttribute, schema);
    const fieldSchema = schema.ofProperty(attributeName);

    // If the resource does not have that field, return an empty
    // span (e.g., for the table).
    if (!fieldSchema) {
      return [null, span];
    }

    const field = this.getField(resource, fieldSchema, attributeName, change);
    field.render(span, this.getText(field, fieldSchema, placeholder), fieldSchema.options);

    const title = field.title;
    if (title) {
      span.setAttribute('title', title);
    }
    span.setAttribute('aria-label', this.getAriaLabel(field, schema));

    return [field, span];
  }

  public getField(resource:T,
    fieldSchema:IFieldSchema,
    attributeName:string,
    change:ResourceChangeset<T>|null):DisplayField {
    let field = this.fieldCache[attributeName];

    if (!field) {
      field = this.fieldCache[attributeName] = this.getFieldForCurrentContext(resource, attributeName, fieldSchema);
    }

    field.apply(resource, fieldSchema);
    field.activeChange = change;

    return field;
  }

  private getFieldForCurrentContext(resource:T, attributeName:string, fieldSchema:IFieldSchema):DisplayField {
    const context:DisplayFieldContext = { container: this.container, injector: this.injector, options: this.options };

    // We handle multi value fields differently in the single view context
    const isCustomMultiLinesField = ['[]CustomOption'].indexOf(fieldSchema.type) >= 0;
    if (this.container === 'single-view' && isCustomMultiLinesField) {
      return new MultipleLinesCustomOptionsDisplayField(attributeName, context) as DisplayField;
    }
    const isUserMultiLinesField = ['[]User'].indexOf(fieldSchema.type) >= 0;
    if (this.container === 'single-view' && isUserMultiLinesField) {
      return new MultipleLinesUserFieldModule(attributeName, context) as DisplayField;
    }

    // We handle progress differently in the timeline
    if (this.container === 'timeline' && attributeName === 'percentageDone') {
      return new ProgressTextDisplayField(attributeName, context);
    }

    // We want to render an combined edit field but the display field must
    // show the original attribute
    if (this.container === 'table' && ['startDate', 'dueDate', 'date'].includes(attributeName)) {
      return new DateDisplayField(attributeName, context);
    }

    return this.displayFieldService.getField(resource, attributeName, fieldSchema, context);
  }

  private getText(field:DisplayField, fieldSchema:IFieldSchema, placeholder?:string):string {
    if (field.isEmpty()) {
      return placeholder || this.getDefaultPlaceholder(fieldSchema);
    } else {
      return field.valueString;
    }
  }

  private setSpanAttributes(span:HTMLElement, field:DisplayField, name:string, resource:T, change:ResourceChangeset<T>|null):void {
    span.classList.add(displayClassName, name);
    span.dataset.fieldName = name;

    // Make span tabbable unless it's an id field
    span.setAttribute('tabindex', name === 'id' ? '-1' : '0');

    if (field.required) {
      span.classList.add(requiredClassName);
    }

    if (field.isEmpty()) {
      span.classList.add(placeholderClassName);
    }

    const schema = this.schema(resource, change);
    if (this.isAttributeEditable(schema, name)) {
      span.classList.add(editableClassName);
      span.setAttribute('role', 'button');
    } else {
      span.classList.add(readOnlyClassName);
    }
  }

  private isAttributeEditable(schema:SchemaResource, fieldName:string) {
    // We need to handle start/due date cases like they were combined dates
    if (['startDate', 'dueDate', 'date'].includes(fieldName)) {
      fieldName = 'combinedDate';
    }

    return schema.isAttributeEditable(fieldName);
  }

  private getAriaLabel(field:DisplayField, schema:SchemaResource):string {
    let titleContent;
    const labelContent = this.getLabelContent(field);

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

    if (field.writable && schema.isAttributeEditable(field.name)) {
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

  /**
   * Get the attribute name from either the schema if the mappedName method is implemented or
   * return the attribute itself.
   *
   * @param schema
   * @param attribute
   */
  private attributeName(attribute:string, schema:SchemaResource) {
    if (schema.mappedName) {
      return schema.mappedName(attribute);
    } else {
      return attribute;
    }
  }

  private getDefaultPlaceholder(fieldSchema:IFieldSchema):string {
    if (fieldSchema.type === 'Formattable') {
      return this.I18n.t('js.work_packages.placeholders.formattable', { name: fieldSchema.name });
    }

    return cellEmptyPlaceholder;
  }

  private schema(resource:T, change:ResourceChangeset<T>|null) {
    if (change) {
      return change.schema;
    } else if (this.halEditing.typedState(resource).hasValue()) {
      return this.halEditing.typedState(resource).value!.schema;
    } else {
      return this.schemaCache.of(resource) as ISchemaProxy;
    }
  }
}
