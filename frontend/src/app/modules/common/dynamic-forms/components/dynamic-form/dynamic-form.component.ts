import {
  Component,
  Input,
  OnChanges,
  Output,
  ViewChild,
  EventEmitter,
  forwardRef,
} from "@angular/core";
import { FormlyForm } from "@ngx-formly/core";
import { DynamicFormService } from "../../services/dynamic-form/dynamic-form.service";
import {
  IOPDynamicFormSettings,
  IOPFormlyFieldSettings,
} from "../../typings";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { catchError, finalize, take } from "rxjs/operators";
import { HalSource } from "core-app/modules/hal/resources/hal-resource";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { DynamicFieldsService } from "core-app/modules/common/dynamic-forms/services/dynamic-fields/dynamic-fields.service";
import { ControlValueAccessor, FormGroup, NG_VALUE_ACCESSOR } from "@angular/forms";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { FormsService } from "core-app/core/services/forms/forms.service";

/*
* The DynamicFormComponent can be used in two different ways:
* - Standalone Form:
* The DynamicFormComponent loads its settings from the backend, renders
* a full form and handles its submitting.
*
*   <op-dynamic-form [resourcePath]="resourcePath"
*                    [resourceId]="resourceId"
*                    (submitted)="onSubmitted($event)">
*   </op-dynamic-form>
*
* In order to work as an standalone form, it will always need the 'resourcePath'
* @Input and, optionally, the 'resourceId' @Input if we are editing a resource.
*
* - FormControl:
* The DynamicFormComponent can be used inside a FormGroup as a FormControl:
*
*   <op-dynamic-form  formControlName="workpackage" [settings]="formSettings">
*   </op-dynamic-form>
*
* In this case, we need to provide the 'settings' @Input, which is basically an
* object that mimics a backend form configuration (IOPFormSettings) but formatted
* to make it easier.
*
* When used as a FormControl (formControlName), the DynamicFormComponent will set
* the entire form value as the value of the FormControl. Using it as a FormGroup
* (formGroupName) would require to pass down the configuration of the form in order
* to use the DynamicFormComponent, which would make no sense for this use case.
*/

@Component({
  selector: "op-dynamic-form",
  templateUrl: "./dynamic-form.component.html",
  styleUrls: ["./dynamic-form.component.scss"],
  providers: [
    DynamicFormService,
    DynamicFieldsService,
    {
      provide: NG_VALUE_ACCESSOR,
      multi: true,
      useExisting: forwardRef(() => DynamicFormComponent),
    }
  ]
})
export class DynamicFormComponent extends UntilDestroyedMixin implements ControlValueAccessor, OnChanges {
  @Input() resourceId:string;
  @Input() resourcePath:string;
  @Input() settings:{
    payload: IOPFormModel,
    schema: IOPFormSchema,
    [nonUsedSchemaKeys:string]:any,
  };
  // Chance to modify the dynamicFormFields settings before the form is rendered
  @Input() fieldsSettingsPipe: (dynamicFieldsSettings:IOPFormlyFieldSettings[]) => IOPFormlyFieldSettings[];
  @Input() showNotifications = true;
  @Input() showValidationErrorsOn: 'change' | 'blur' | 'submit' | 'never' = 'submit';
  @Input() handleSubmit = true;
  @Input() helpTextAttributeScope = '';

  @Output() modelChange = new EventEmitter<IOPFormModel>();
  @Output() submitted = new EventEmitter<HalSource>();
  @Output() errored = new EventEmitter<IOPFormErrorResponse>();

  isStandaloneForm:boolean;
  fields: IOPFormlyFieldSettings[];
  model: IOPFormModel;
  form: FormGroup;
  resourceEndpoint:string;
  inFlight:boolean;
  text = {
    save: this._I18n.t('js.button_save'),
    validation_error_message: this._I18n.t('js.forms.validation_error_message'),
    load_error_message: this._I18n.t('js.forms.load_error_message'),
    submit_success_message: this._I18n.t('js.forms.submit_success_message'),
  };
  onChange = (_:any) => { }
  onTouch = () => { }

  @ViewChild(FormlyForm)
  set dynamicForm(dynamicForm: FormlyForm) {
    this._dynamicFormService.registerForm(dynamicForm);
  }

  constructor(
    private _dynamicFormService: DynamicFormService,
    private _I18n:I18nService,
    private _pathHelperService:PathHelperService,
    private _notificationsService:NotificationsService,
    private _formsService: FormsService,
  ) {
    super();
  }

  writeValue(value:{[key:string]:any}):void {
    if (value) {
      this.model = value;
    }
  }

  registerOnChange(fn: (_: any) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: any): void {
    this.onTouch = fn;
  }

  setDisabledState(disabled: boolean): void {
    disabled ? this.form.disable() : this.form.enable();
  }

  ngOnChanges() {
    this.isStandaloneForm = !this.settings;

    if (this.isStandaloneForm) {
      this._setupStandaloneDynamicForm();
    } else {
      this._setupDynamicFormControl();
    }
  }

  onModelChange(changes:any) {
    this.modelChange.emit(changes);
    this.onChange(changes);
    this.onTouch();
  }

  submitForm(form:FormGroup) {
    if (!(this.isStandaloneForm && this.handleSubmit)) {
      return;
    }

    this.inFlight = true;
    this._dynamicFormService
      .submit$(form, this.resourceEndpoint, this.resourceId)
      .pipe(
        finalize(() => this.inFlight = false)
      )
      .subscribe(
        (formResource:HalSource) => {
          this.submitted.emit(formResource);
          this.showNotifications && this._notificationsService.addSuccess(this.text.submit_success_message);
        },
        (error:IOPFormErrorResponse) => {
          this.errored.emit(error);
          this.showNotifications && this._notificationsService.addError(this.text.validation_error_message);
        },
      );
  }

  validateForm() {
    this._formsService.validateForm$(this.form, this.resourceEndpoint).subscribe();
  }

  private _setupStandaloneDynamicForm() {
    this.resourceEndpoint = `${this._pathHelperService.api.v3.apiV3Base}${this.resourcePath}`;
    const url = `${this.resourceEndpoint}/${this.resourceId ? this.resourceId + '/' : ''}form`;

    this._dynamicFormService
      .getSettingsFromBackend$(url)
      .pipe(
        take(1),
        catchError(error => {
          this._notificationsService.addError(this.text.load_error_message);
          throw error;
        })
      )
      .subscribe(dynamicFormSettings => this._setupDynamicForm(dynamicFormSettings));
  }

  private _setupDynamicFormControl() {
    const formattedSettings:IOPFormSettings = {
      _embedded: {
        payload: this.settings.payload,
        schema: this.settings.schema,
      }
    }
    const dynamicFormSettings = this._dynamicFormService.getSettings(formattedSettings);

    this._setupDynamicForm(dynamicFormSettings);
  }

  private _setupDynamicForm({fields, model, form}:IOPDynamicFormSettings) {
    this.form = form;
    this.fields = this.fieldsSettingsPipe ? this.fieldsSettingsPipe(fields) : fields;
    this.model = model;

    if (!this.isStandaloneForm) {
      this.onChange(this.model);
    }
  }
}
