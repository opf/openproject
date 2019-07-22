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
import {EditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler";
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken
} from "core-app/modules/fields/edit/edit-field.component";
import {createLocalInjector} from "core-app/modules/fields/edit/editing-portal/edit-form-portal.injector";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {WorkPackageChangeset} from "core-components/wp-edit-form/work-package-changeset";
import {EditFieldService, IEditFieldType} from "core-app/modules/fields/edit/edit-field.service";
import {EditChangeset} from "core-app/modules/fields/changeset/edit-changeset";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

@Component({
  selector: 'edit-form-portal',
  templateUrl: './edit-form-portal.component.html'
})
export class EditFormPortalComponent implements OnInit, OnDestroy, AfterViewInit {
  @Input() schemaInput:IFieldSchema;
  @Input() changesetInput:EditChangeset<HalResource|{ [key:string]:unknown; }>;
  @Input() editFieldHandler:EditFieldHandler;
  @Output() public onEditFieldReady = new EventEmitter<void>();

  public handler:EditFieldHandler;
  public schema:IFieldSchema;
  public changeset:EditChangeset<HalResource|{ [key:string]:unknown; }>;
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
      this.changeset = this.changesetInput;

    } else {
      this.handler = this.injector.get<EditFieldHandler>(OpEditingPortalHandlerToken);
      this.schema = this.injector.get<IFieldSchema>(OpEditingPortalSchemaToken);
      this.changeset = this.injector.get<EditChangeset<HalResource|{ [key:string]:unknown; }>>(OpEditingPortalChangesetToken);
    }

    this.componentClass = this.editField.getClassFor(this.handler.fieldName, this.schema.type);
    this.fieldInjector = createLocalInjector(this.injector, this.changeset, this.handler, this.schema);
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
