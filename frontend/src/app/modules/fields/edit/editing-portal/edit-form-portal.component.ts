import {Component, Inject, Injector} from "@angular/core";
import {
  EditFieldComponent,
  EditFieldLocals,
  OpEditingPortalLocalsToken
} from "core-app/modules/fields/edit/edit-field.component";
import {WorkPackageEditFieldHandler} from "core-components/wp-edit-form/work-package-edit-field-handler";

@Component({
  templateUrl: './edit-form-portal.component.html'
})
export class EditFormPortalComponent {
  readonly handler:WorkPackageEditFieldHandler = this.locals.handler;
  readonly editFieldComponent:EditFieldComponent = this.locals.field.component;

  constructor(@Inject(OpEditingPortalLocalsToken) readonly locals:EditFieldLocals,
              readonly injector:Injector) {
  }
}
