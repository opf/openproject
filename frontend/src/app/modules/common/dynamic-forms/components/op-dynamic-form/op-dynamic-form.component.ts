import {
  Component,
  Input,
  OnChanges,
  ViewChild
} from "@angular/core";
import { FormlyForm } from "@ngx-formly/core";
import { Observable } from "rxjs";
import { DynamicFormService } from "../../services/dynamic-form.service";
import { IDynamicForm, IFormModel } from "../../typings";

@Component({
  selector: "op-dynamic-form",
  templateUrl: "./op-dynamic-form.component.html",
  styleUrls: ["./op-dynamic-form.component.scss"],
  providers: [DynamicFormService]
})
export class OpDynamicFormComponent implements OnChanges {
  @Input() formId: string;
  @Input() projectId: string;
  @Input() typeHref: string;
  // TODO: Implement the following @Inputs (resourceType + )
  /* @Input() formHref: string;
  @Input() config: string;
  @Input() opForm: string;*/
  dynamicForm$: Observable<IDynamicForm>;

  @ViewChild(FormlyForm)
  set formlyForm(formlyForm: FormlyForm) {
    this.dynamicFormService.registerForm(formlyForm);
  }

  constructor(readonly dynamicFormService: DynamicFormService) {}

  ngOnChanges() {
    this.dynamicForm$ = this.dynamicFormService
      .getForm$(this.typeHref, this.formId, this.projectId)
  }

  saveForm(formModel:IFormModel) {
    this.dynamicFormService
          .submitForm(formModel)
          .subscribe((response) => console.log('response', response));
  }
}
