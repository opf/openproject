//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, ElementRef, Injector, Input, OnInit, ViewChild, inject } from '@angular/core';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { Constructor } from 'core-app/core/util-types';
import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';

@Component({
  selector: 'display-field',
  template: '<span #displayFieldContainer></span>',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class DisplayFieldComponent implements OnInit {
  private injector = inject(Injector);
  private displayFieldService = inject(DisplayFieldService);
  private schemaCache = inject(SchemaCacheService);

  @Input() resource:HalResource;

  @Input() fieldName:string;

  @Input() displayClass?:Constructor<DisplayField>;

  @Input() containerType:'table'|'single-view'|'timeline' = 'table';

  @Input() displayFieldOptions:Record<string, unknown> = {};

  @ViewChild('displayFieldContainer') container:ElementRef<HTMLSpanElement>;

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
