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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { AfterViewInit, ChangeDetectorRef, Component, DestroyRef, ElementRef, EventEmitter, Injector, Input, OnDestroy, OnInit, Output, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { HalResourceEditFieldHandler } from 'core-app/shared/components/fields/edit/field-handler/hal-resource-edit-field-handler';
import { merge } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { createLocalInjector } from 'core-app/shared/components/fields/edit/editing-portal/edit-form-portal.injector';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { EditFieldService, IEditFieldType } from 'core-app/shared/components/fields/edit/edit-field.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'edit-form-portal',
  templateUrl: './edit-form-portal.component.html',
  standalone: false,
})
export class EditFormPortalComponent implements OnInit, OnDestroy, AfterViewInit {
  readonly injector = inject(Injector);
  readonly editField = inject(EditFieldService);
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly cdRef = inject(ChangeDetectorRef);
  private readonly destroyRef = inject(DestroyRef);

  @Input() schemaInput:IFieldSchema;

  @Input() changeInput:ResourceChangeset;

  @Input() editFieldHandler:EditFieldHandler;

  // eslint-disable-next-line @angular-eslint/no-output-on-prefix
  @Output() public onEditFieldReady = new EventEmitter<void>();

  public handler:EditFieldHandler;

  public schema:IFieldSchema;

  public change:ResourceChangeset;

  public fieldInjector:Injector;

  public componentClass:IEditFieldType;

  public htmlId:string;

  public label:string;

  public get hasErrors():boolean {
    return this.handler instanceof HalResourceEditFieldHandler && this.handler.isErrorenous;
  }

  ngOnInit() {
    if (this.editFieldHandler && this.schemaInput) {
      this.handler = this.editFieldHandler;
      this.schema = this.schemaInput;
      this.change = this.changeInput;
    } else {
      this.handler = this.injector.get<EditFieldHandler>(OpEditingPortalHandlerToken);
      this.schema = this.injector.get<IFieldSchema>(OpEditingPortalSchemaToken);
      this.change = this.injector.get<ResourceChangeset>(OpEditingPortalChangesetToken);
    }

    this.componentClass = this.editField.getSpecificClassFor(this.change.pristineResource._type, this.handler.fieldName, this.schema.type);
    this.fieldInjector = createLocalInjector(this.injector, this.change, this.handler, this.schema);

    if (this.handler instanceof HalResourceEditFieldHandler) {
      merge(this.handler.errorsChanged$, this.handler.stateChanged$)
        .pipe(takeUntil(this.handler.onDestroy), takeUntilDestroyed(this.destroyRef))
        .subscribe(() => this.cdRef.detectChanges());
    }
  }

  ngOnDestroy() {
    this.onEditFieldReady.complete();
  }

  ngAfterViewInit() {
    // Fire in a timeout to avoid same execution context in AfterViewInit
    const ready = setTimeout(() => {
      this.onEditFieldReady.emit();
    });
    this.destroyRef.onDestroy(() => clearTimeout(ready));
  }
}
