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
import { I18nService } from "core-app/modules/common/i18n/i18n.service";

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
  text = {
    save: this.I18n.t('js.button_save'),
  };

  @ViewChild(FormlyForm)
  set formlyForm(formlyForm: FormlyForm) {
    this.dynamicFormService.registerForm(formlyForm);
  }

  constructor(
    readonly dynamicFormService: DynamicFormService,
    readonly I18n:I18nService,
  ) {}

  ngOnChanges() {
    this.dynamicForm$ = this.dynamicFormService
      .getForm$(this.typeHref, this.formId, this.projectId)
  }

  saveForm(formModel:IFormModel) {
    this.dynamicFormService
          .submitForm$(formModel)
          .subscribe();
  }
}
