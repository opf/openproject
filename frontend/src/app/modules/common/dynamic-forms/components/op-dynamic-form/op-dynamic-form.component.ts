import {
  Component,
  Input,
  OnChanges,
  ViewChild
} from "@angular/core";
import { FormGroup } from "@angular/forms";
import { FormlyForm } from "@ngx-formly/core";
import { Observable } from "rxjs";
import { DynamicFormService } from "../../services/dynamic-form.service";
import { IDynamicForm } from "../../typings";

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

  form:FormGroup;
  dynamicForm$: Observable<IDynamicForm>;

  @ViewChild(FormlyForm)
  set formlyForm(formlyForm: FormlyForm) {
    this.dynamicFormService.registerForm(formlyForm);
  }

  constructor(readonly dynamicFormService: DynamicFormService) {}

  ngOnChanges() {
    this.form = new FormGroup({});
    this.dynamicForm$ = this.dynamicFormService
      .getForm$(this.typeHref, this.formId, this.projectId)
  }
}
