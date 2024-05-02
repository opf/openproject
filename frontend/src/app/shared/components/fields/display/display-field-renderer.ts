import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import {
  DisplayFieldContext,
  DisplayFieldService,
} from 'core-app/shared/components/fields/display/display-field.service';
import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';

export const editableClassName = '-editable';
export const requiredClassName = '-required';
export const readOnlyClassName = '-read-only';
export const placeholderClassName = '-placeholder';
export const displayClassName = 'inline-edit--display-field';
export const displayTriggerLink = 'inline-edit--display-trigger';
export const editFieldContainerClass = 'inline-edit--container';

export class DisplayFieldRenderer<T extends HalResource = HalResource> {
  @InjectField() displayFieldService:DisplayFieldService;

  @InjectField() schemaCache:SchemaCacheService;

  @InjectField() halEditing:HalResourceEditingService;

  @InjectField() I18n!:I18nService;

  /** We cache the previously used fields to avoid reinitialization */
  private fieldCache:{ [key:string]:DisplayField } = {};

  constructor(
    public readonly injector:Injector,
    public readonly container:'table'|'single-view'|'timeline',
    public readonly options:{ [key:string]:unknown } = {},
  ) {
  }

  public render(
    resource:T,
    name:string,
    change:ResourceChangeset<T>|null,
  ):HTMLSpanElement {
    const [field, span] = this.renderFieldValue(resource, name, change);

    if (field === null) {
      return span;
    }

    this.setSpanAttributes(span, field, name, resource, change);

    return span;
  }

  public renderFieldValue(
    resource:T,
    requestedAttribute:string,
    change:ResourceChangeset<T>|null,
  ):[DisplayField|null, HTMLSpanElement] {
    const span = document.createElement('span');
    const schema = this.schema(resource, change);
    const attributeName = this.attributeName(requestedAttribute, schema);
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call
    const fieldSchema = schema.ofProperty(attributeName) as IFieldSchema;

    // If the resource does not have that field, return an empty
    // span (e.g., for the table).
    if (!fieldSchema) {
      return [null, span];
    }

    const field = this.getField(resource, fieldSchema, attributeName, change);
    field.render(span, this.getText(field), fieldSchema.options);

    const { title } = field;
    if (title && !span.getAttribute('title')) {
      span.setAttribute('title', title);
    }
    span.setAttribute('aria-label', this.getAriaLabel(field, schema));

    return [field, span];
  }

  public getField(
    resource:T,
    fieldSchema:IFieldSchema,
    attributeName:string,
    change:ResourceChangeset<T>|null,
  ):DisplayField {
    let field = this.fieldCache[attributeName];

    if (!field) {
      // eslint-disable-next-line no-multi-assign
      field = this.fieldCache[attributeName] = this.getFieldForCurrentContext(resource, attributeName, fieldSchema);
    }

    field.apply(resource, fieldSchema);
    field.activeChange = change;

    return field;
  }

  private getFieldForCurrentContext(resource:T, attributeName:string, fieldSchema:IFieldSchema):DisplayField {
    const context:DisplayFieldContext = { container: this.container, injector: this.injector, options: this.options };
    return this.displayFieldService.getField(resource, attributeName, fieldSchema, context);
  }

  private getText(field:DisplayField):string {
    if (field.isEmpty()) {
      return field.placeholder;
    }

    return field.valueString;
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

  private isAttributeEditable(schema:SchemaResource, fieldName:string):boolean {
    // We need to handle start/due date cases like they were combined dates
    if (['startDate', 'dueDate', 'date'].includes(fieldName)) {
      fieldName = 'combinedDate';
    }

    // eslint-disable-next-line @typescript-eslint/no-unsafe-call
    return schema.isAttributeEditable(fieldName) as boolean;
  }

  private getAriaLabel(field:DisplayField, schema:SchemaResource):string {
    let titleContent;
    const labelContent = this.getLabelContent(field);

    if (field.isFormattable && !field.isEmpty()) {
      try {
        titleContent = _.escape(jQuery(`<div>${labelContent}</div>`).text());
      } catch (e) {
        console.error('Failed to parse formattable labelContent');
        titleContent = `Label for ${field.displayName}`;
      }
    } else {
      titleContent = labelContent;
    }

    // eslint-disable-next-line @typescript-eslint/no-unsafe-call
    if (field.writable && !!schema.isAttributeEditable(field.name)) {
      return this.I18n.t('js.inplace.button_edit', { attribute: `${field.displayName} ${titleContent}` });
    }
    return `${field.displayName} ${titleContent}`;
  }

  private getLabelContent(field:DisplayField):string {
    if (field.isEmpty()) {
      return this.I18n.t('js.inplace.null_value_label');
    }
    return field.valueString;
  }

  /**
   * Get the attribute name from either the schema if the mappedName method is implemented or
   * return the attribute itself.
   *
   * @param schema
   * @param attribute
   */
  private attributeName(attribute:string, schema:SchemaResource):string {
    if (schema.mappedName) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      return schema.mappedName(attribute) as string;
    }

    return attribute;
  }

  private schema(resource:T, change:ResourceChangeset<T>|null):SchemaResource {
    if (change) {
      return change.schema;
    }

    if (this.halEditing.typedState(resource).hasValue()) {
      const val = this.halEditing.typedState(resource).value as { schema:SchemaResource };
      return val.schema;
    }

    return this.schemaCache.of(resource);
  }
}
