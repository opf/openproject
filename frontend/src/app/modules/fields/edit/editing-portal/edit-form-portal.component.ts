import {
  AfterViewInit,
  EventEmitter,
  Component,
  ElementRef,
  Injector,
  Input,
  OnDestroy,
  OnInit,
  Output
} from "@angular/core";
import {EditField} from "core-app/modules/fields/edit/edit.field.module";
import {IEditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler.interface";
import {
  OpEditingPortalFieldToken,
  OpEditingPortalHandlerToken
} from "core-app/modules/fields/edit/edit-field.component";
import {createLocalInjector} from "core-app/modules/fields/edit/editing-portal/edit-form-portal.injector";

@Component({
  selector: 'edit-form-portal',
  templateUrl: './edit-form-portal.component.html'
})
export class EditFormPortalComponent implements OnInit, OnDestroy, AfterViewInit {
  @Input() editFieldInput:EditField;
  @Input() editFieldHandler:IEditFieldHandler;
  @Output() public onEditFieldReady = new EventEmitter<void>();

  public handler:IEditFieldHandler;
  public editField:EditField;
  public fieldInjector:Injector;

  constructor(readonly injector:Injector,
              readonly elementRef:ElementRef) {
  }

  ngOnInit() {
    if (this.editFieldHandler && this.editFieldInput) {
      this.handler = this.editFieldHandler;
      this.editField = this.editFieldInput;
    } else {
      this.handler = this.injector.get<IEditFieldHandler>(OpEditingPortalHandlerToken);
      this.editField = this.injector.get<EditField>(OpEditingPortalFieldToken);
    }

    this.fieldInjector = createLocalInjector(this.injector, this.handler, this.editField);
  }

  ngOnDestroy() {
    this.onEditFieldReady.complete();
  }

  ngAfterViewInit() {
    // Fire in a timeout to avoid same execution context in AfterViewInit
    setTimeout(() => {
      // Call $onInit once the field is ready
      this.editField.$onInit(this.elementRef.nativeElement);
      this.onEditFieldReady.emit();
    });
  }
}
