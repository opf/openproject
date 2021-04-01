import {
  Component,
  Input,
  OnChanges,
  ViewChild,
} from "@angular/core";
import { FormlyForm } from "@ngx-formly/core";
import { Observable } from "rxjs";
import { DynamicFormService } from "../../services/dynamic-form.service";
import { IDynamicForm, IFormModel } from "../../typings";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { finalize } from "rxjs/operators";

@Component({
  selector: "op-dynamic-form",
  templateUrl: "./op-dynamic-form.component.html",
  styleUrls: ["./op-dynamic-form.component.scss"],
  providers: [DynamicFormService]
})
export class OpDynamicFormComponent implements OnChanges {
  @Input() resourceId:string;
  @Input() resourcePath:string;

  resourceEndpoint:string;
  dynamicForm$: Observable<IDynamicForm>;
  text = {
    save: this._I18n.t('js.button_save'),
  };
  inFlight:boolean;

  @ViewChild(FormlyForm)
  set formlyForm(formlyForm: FormlyForm) {
    this._dynamicFormService.registerForm(formlyForm);
  }

  constructor(
    private _dynamicFormService: DynamicFormService,
    private _I18n:I18nService,
    private _pathHelperService:PathHelperService,
  ) {}

  ngOnChanges() {
    if (!this.resourcePath) {
      return;
    }

    this.resourceEndpoint = `${this._pathHelperService.api.v3.apiV3Base}${this.resourcePath}`;
    const url = `${this.resourceEndpoint}/${this.resourceId ? this.resourceId + '/' : ''}form`;
    this.dynamicForm$ = this._dynamicFormService.getForm$(url);
  }

  submitForm(formModel:IFormModel) {
    this.inFlight = true;
    this._dynamicFormService
      .submitForm$(formModel, this.resourceEndpoint, this.resourceId)
      .pipe(
        finalize(() => this.inFlight = false)
      )
      .subscribe();
  }
}
