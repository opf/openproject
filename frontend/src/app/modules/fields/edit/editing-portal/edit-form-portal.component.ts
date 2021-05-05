import {
  AfterViewInit,
  Component,
  ElementRef,
  EventEmitter,
  Injector,
  Input,
  OnDestroy,
  OnInit,
  Output
} from "@angular/core";
import { EditFieldHandler } from "core-app/modules/fields/edit/editing-portal/edit-field-handler";
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken
} from "core-app/modules/fields/edit/edit-field.component";
import { createLocalInjector } from "core-app/modules/fields/edit/editing-portal/edit-form-portal.injector";
import { IFieldSchema } from "core-app/modules/fields/field.base";
import { EditFieldService, IEditFieldType } from "core-app/modules/fields/edit/edit-field.service";
import { ResourceChangeset } from "core-app/modules/fields/changeset/resource-changeset";

@Component({
  selector: 'edit-form-portal',
  templateUrl: './edit-form-portal.component.html'
})
export class EditFormPortalComponent implements OnInit, OnDestroy, AfterViewInit {
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

  constructor(readonly injector:Injector,
              readonly editField:EditFieldService,
              readonly elementRef:ElementRef) {
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
