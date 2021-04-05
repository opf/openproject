import {
  Component,
  Input,
  OnChanges,
  Output,
  ViewChild,
  EventEmitter,
} from "@angular/core";
import { FormlyForm } from "@ngx-formly/core";
import { Observable } from "rxjs";
import { DynamicFormService } from "../../services/dynamic-form.service";
import { IOPDynamicForm, IFormError, IFormModel } from "../../typings";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { finalize } from "rxjs/operators";
import { HalSource } from "core-app/modules/hal/resources/hal-resource";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";

@Component({
  selector: "op-dynamic-form",
  templateUrl: "./op-dynamic-form.component.html",
  styleUrls: ["./op-dynamic-form.component.scss"],
  providers: [DynamicFormService]
})
export class OpDynamicFormComponent implements OnChanges {
  @Input() resourceId:string;
  @Input() resourcePath:string;
  @Input() showNotifications = true;

  @Output() submitted = new EventEmitter<HalSource>();
  @Output() errored = new EventEmitter<IFormError>();

  resourceEndpoint:string;
  dynamicForm$: Observable<IOPDynamicForm>;
  text = {
    save: this._I18n.t('js.button_save'),
    error_message: this._I18n.t('js.forms.error_message'),
    success_message: this._I18n.t('js.forms.success_message'),
  };
  inFlight:boolean;

  @ViewChild(FormlyForm)
  set dynamicForm(dynamicForm: FormlyForm) {
    this._dynamicFormService.registerForm(dynamicForm);
  }

  constructor(
    private _dynamicFormService: DynamicFormService,
    private _I18n:I18nService,
    private _pathHelperService:PathHelperService,
    protected _notificationsService:NotificationsService,
  ) {}

  ngOnChanges() {
    if (!this.resourcePath) {
      return;
    }

    this.resourceEndpoint = `${this._pathHelperService.api.v3.apiV3Base}${this.resourcePath}`;
    // TODO: Does this work for all resource types?
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
      .subscribe(
        (formResource:HalSource) => {
          this.submitted.emit(formResource);
          this.showNotifications && this._notificationsService.addSuccess(this.text.success_message);
        },
        (error:IFormError) => {
          this.errored.emit(error);
          this.showNotifications && this._notificationsService.addError(this.text.error_message);
        },
      );
  }
}
