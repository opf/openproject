import { ChangeDetectionStrategy, Component, ElementRef, Injector, Input, OnInit, ViewChild } from '@angular/core';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { Constructor } from '@angular/cdk/table';
import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';

@Component({
  selector: 'display-field',
  template: '<span #displayFieldContainer></span>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DisplayFieldComponent implements OnInit {
  @Input() resource:HalResource;

  @Input() fieldName:string;

  @Input() displayClass?:Constructor<DisplayField>;

  @Input() containerType:'table'|'single-view'|'timeline' = 'table';

  @Input() displayFieldOptions:{ [key:string]:unknown } = {};

  @ViewChild('displayFieldContainer') container:ElementRef<HTMLSpanElement>;

  constructor(
    private injector:Injector,
    private displayFieldService:DisplayFieldService,
    private schemaCache:SchemaCacheService,
  ) {
  }

  ngOnInit():void {
    void this.schemaCache
      .ensureLoaded(this.resource)
      .then((schema) => {
        const proxied = this.schemaCache.proxied(this.resource, schema);
        this.fieldName = this.attributeName(this.fieldName, proxied);
        this.render(proxied.ofProperty(this.fieldName));
      });
  }

  render(fieldSchema:IFieldSchema):void {
    const field = this.getDisplayFieldInstance(fieldSchema);
    field.apply(this.resource, fieldSchema);

    const container = this.container.nativeElement;
    container.hidden = false;

    // Default the field to a placeholder when rendering
    if (field.isEmpty()) {
      container.textContent = '-';
    } else {
      field.render(container, field.valueString);
    }
  }

  private getDisplayFieldInstance(fieldSchema:IFieldSchema) {
    if (this.displayClass) {
      // eslint-disable-next-line new-cap
      const instance = new this.displayClass(this.fieldName, this.displayFieldContext);
      instance.apply(this.resource, fieldSchema);
      return instance;
    }

    return this.displayFieldService.getField(
      this.resource,
      this.fieldName,
      fieldSchema,
      this.displayFieldContext,
    );
  }

  private attributeName(attribute:string, schema:SchemaResource):string {
    if (schema.mappedName) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      return schema.mappedName(attribute) as string;
    }

    return attribute;
  }

  private get displayFieldContext() {
    return { injector: this.injector, container: this.containerType, options: this.displayFieldOptions };
  }
}
