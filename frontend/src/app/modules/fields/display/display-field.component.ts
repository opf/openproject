import { ChangeDetectionStrategy, Component, ElementRef, Injector, Input, OnInit, ViewChild } from '@angular/core';
import { IFieldSchema } from "core-app/modules/fields/field.base";
import { DisplayFieldService } from "core-app/modules/fields/display/display-field.service";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";
import { Constructor } from "@angular/cdk/table";
import { DisplayField } from "core-app/modules/fields/display/display-field.module";

@Component({
  selector: 'display-field',
  template: '<span #displayFieldContainer></span>',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DisplayFieldComponent implements OnInit {
  @Input() resource:HalResource;
  @Input() fieldName:string;
  @Input() displayClass?:Constructor<DisplayField>;

  @Input() containerType:'table'|'single-view'|'timeline' = 'table';
  @Input() displayFieldOptions:{[key:string]:unknown} = {};

  @ViewChild('displayFieldContainer') container:ElementRef<HTMLSpanElement>;

  constructor(private injector:Injector,
              private displayFieldService:DisplayFieldService,
              private schemaCache:SchemaCacheService) {
  }

  ngOnInit() {
    this.schemaCache
      .ensureLoaded(this.resource)
      .then(schema => {
        this.render(schema[this.fieldName]);
      });
  }

  render(fieldSchema:IFieldSchema) {
    const field = this.getDisplayFieldInstance(fieldSchema);

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
      const instance = new this.displayClass(this.fieldName, this.displayFieldContext);
      instance.apply(this.resource, fieldSchema);
      return instance;
    }

    return this.displayFieldService.getField(
      this.resource,
      this.fieldName,
      fieldSchema,
      this.displayFieldContext
    );
  }

  private get displayFieldContext() {
    return { injector: this.injector, container: this.containerType, options: this.displayFieldOptions };
  }
}
