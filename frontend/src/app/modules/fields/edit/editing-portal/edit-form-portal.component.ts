import {AfterViewInit, EventEmitter, Component, ElementRef, Injector, Input, OnDestroy, OnInit} from "@angular/core";
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

  public handler:IEditFieldHandler;
  public editField:EditField;
  public fieldInjector:Injector;

  public onAfterViewInit = new EventEmitter<void>();

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
    this.onAfterViewInit.complete();
  }

  ngAfterViewInit() {
    // Fire in a timeout to avoid same execution contextg in AfterViewInit
    setTimeout(() => this.onAfterViewInit.emit());
  }
}
