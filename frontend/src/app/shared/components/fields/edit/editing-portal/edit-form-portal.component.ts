import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, EventEmitter, Injector, Input, OnDestroy, OnInit, Output, inject } from '@angular/core';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { HalResourceEditFieldHandler } from 'core-app/shared/components/fields/edit/field-handler/hal-resource-edit-field-handler';
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
  selector: 'edit-form-portal',
  templateUrl: './edit-form-portal.component.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class EditFormPortalComponent implements OnInit, OnDestroy, AfterViewInit {
  readonly injector = inject(Injector);
  readonly editField = inject(EditFieldService);
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly cdRef = inject(ChangeDetectorRef);

  @Input() schemaInput:IFieldSchema;

  @Input() changeInput:ResourceChangeset;

  @Input() editFieldHandler:EditFieldHandler;

  @Output() public onEditFieldReady = new EventEmitter<void>();

  public handler:EditFieldHandler;

  public schema:IFieldSchema;

  public change:ResourceChangeset;

  public fieldInjector:Injector;

  public componentClass:IEditFieldType;

  public htmlId:string;

  public label:string;

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
      this.handler.errorsChanged$
        .pipe(takeUntil(this.handler.onDestroy))
        .subscribe(() => this.cdRef.detectChanges());

      this.handler.stateChanged$
        .pipe(takeUntil(this.handler.onDestroy))
        .subscribe(() => this.cdRef.detectChanges());
    }
  }

  ngOnDestroy() {
    this.onEditFieldReady.complete();
  }

  ngAfterViewInit() {
    // Fire in a timeout to avoid same execution context in AfterViewInit
    setTimeout(() => {
      this.onEditFieldReady.emit();
    });
  }
}
