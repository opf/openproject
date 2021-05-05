import {
  Component,
  Input,
  OnChanges,
  Output,
  ViewChild,
  EventEmitter,
  forwardRef,
  SimpleChanges,
  ChangeDetectorRef,
} from "@angular/core";
import { FormlyForm } from "@ngx-formly/core";
import { DynamicFormService } from "../../services/dynamic-form/dynamic-form.service";
import {
  IOPDynamicFormSettings,
  IOPFormlyFieldSettings,
} from "../../typings";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { catchError, finalize } from "rxjs/operators";
import { HalSource } from "core-app/modules/hal/resources/hal-resource";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { DynamicFieldsService } from "core-app/modules/common/dynamic-forms/services/dynamic-fields/dynamic-fields.service";
import { ControlValueAccessor, FormGroup, NG_VALUE_ACCESSOR } from "@angular/forms";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { FormsService } from "core-app/core/services/forms/forms.service";

/*
* SETTINGS:
* The DynamicFormComponent can get its settings (payload and fields) in two ways:
*
* - @Input settings:
* Passing down an object that mimics a backend form configuration (IOPFormSettings),
* with and easier format (not _embedded).
*
*   <op-dynamic-form [settings]="formSettings">
*   </op-dynamic-form>
*
* - Backend settings:
* In order to fetch its settings from the backend, the DynamicFormComponent will
* always need the 'resourcePath' @Input and, optionally, the 'resourceId' @Input if
* we are editing a resource.
*
*   <op-dynamic-form [resourcePath]="resourcePath">
*   </op-dynamic-form>
*
* USE CASES:
* The DynamicFormComponent can be used in two ways:
*
* - Standalone Form:
* In order to work as an standalone form, handling the submit operation by
* showing a submit button, the DynamicFormComponent will always need the
* 'resourcePath' @Input and, optionally, the 'resourceId' @Input if we are
* editing a single resource.
*
*   <op-dynamic-form [resourcePath]="projectsPath">
*   </op-dynamic-form>
*
* - FormControl:
* The DynamicFormComponent can be used inside a FormGroup as a FormControl.
*
*   <op-dynamic-form  formControlName="workpackage"
*                     [settings]="formSettings">
*   </op-dynamic-form>
*
* When used as a FormControl (formControlName), the DynamicFormComponent will set
* the entire form value as the value of the FormControl. Using it as a FormGroup
* (formGroupName) would require to pass down the configuration of the form in order
* to use the DynamicFormComponent, which would make no sense because what this
* component does is to generate a form automatically from a configuration object.
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
  // Backend form URL (e.g. https://community.openproject.org/api/v3/projects/dev-large/form)
  @Input() formUrl:string;
  // When using the formUrl @Input(), set the http method to use if it is not 'POST'
  @Input() formHttpMethod: 'post' | 'patch' = 'post';
  // Part of the URL that belongs to the resource type (e.g. '/projects' in the previous example)
  // Use this option when you don't have a form URL, the DynamicForm will build it from the resourcePath
  // for you (⌐■_■).
  @Input() resourcePath:string;
  // Pass the resourceId in case you are editing an existing resource and you don't have the Form URL.
  @Input() resourceId:string;
  @Input() settings:IOPFormSettings;
  // Chance to modify the dynamicFormFields settings before the form is rendered
  @Input() fieldsSettingsPipe: (dynamicFieldsSettings:IOPFormlyFieldSettings[]) => IOPFormlyFieldSettings[];
  @Input() showNotifications = true;
  @Input() showValidationErrorsOn: 'change' | 'blur' | 'submit' | 'never' = 'submit';
  @Input() handleSubmit = true;
  @Input() set model (payload:IOPFormModel) {
    if (!this.innerModel && !payload) {
      return;
    }

    const formattedModel = this._dynamicFieldsService.getFormattedFieldsModel(payload);
    this.innerModel = formattedModel;
  };

  /** Initial payload to POST to the form */
  @Input() initialPayload:Object = {};

  @Output() modelChange = new EventEmitter<IOPFormModel>();
  @Output() submitted = new EventEmitter<HalSource>();
  @Output() errored = new EventEmitter<IOPFormErrorResponse>();

  fields:IOPFormlyFieldSettings[];
  form: FormGroup;
  formEndpoint:string | null;
  inFlight:boolean;
  text = {
    save: this._I18n.t('js.button_save'),
    validation_error_message: this._I18n.t('js.forms.validation_error_message'),
    load_error_message: this._I18n.t('js.forms.load_error_message'),
    successful_update: this._I18n.t('js.notice_successful_update'),
    successful_create: this._I18n.t('js.notice_successful_create'),
  };
  noSettingsSourceErrorMessage = `DynamicFormComponent needs a settings or resourcePath @Input
  in order to fetch its setting. Please provide one.`;
  noPathToSubmitToError = `DynamicForm needs a resourcePath input in order to be submitted 
  and validated. Please provide one.`;
  onChange:Function;
  onTouch:Function;
  innerModel:IOPFormModel;

  get model() {
    return this.form.value;
  }

  get isFormControl():boolean {
    return !!this.onChange && !!this.onTouch;
  }
  get isStandaloneForm():boolean {
    return !this.isFormControl;
  }

  @ViewChild(FormlyForm)
  set dynamicForm(dynamicForm: FormlyForm) {
    this._dynamicFormService.registerForm(dynamicForm);
  }

  constructor(
    private _dynamicFormService: DynamicFormService,
    private _dynamicFieldsService: DynamicFieldsService,
    private _I18n:I18nService,
    private _pathHelperService:PathHelperService,
    private _notificationsService:NotificationsService,
    private _formsService: FormsService,
    private _changeDetectorRef: ChangeDetectorRef,
  ) {
    super();
  }

  writeValue(value:{[key:string]:any}):void {
    if (value) {
      this.innerModel = value;
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

  ngOnChanges(changes:SimpleChanges) {
    this._initializeDynamicForm(
      changes?.settings?.currentValue,
      this.resourcePath,
      this.resourceId,
      this.formUrl,
      this.innerModel || this.initialPayload
    );
  }

  onModelChange(changes:any) {
    this.modelChange.emit(changes);

    if (!this.isStandaloneForm) {
      this.onChange(changes);
      this.onTouch();
    }
  }

  submitForm(form:FormGroup) {
    if (!(this.isStandaloneForm && this.handleSubmit)) {
      return;
    }

    if (!this.formEndpoint) {
      throw new Error(this.noPathToSubmitToError);
    }

    this.inFlight = true;
    this._dynamicFormService
      .submit$(form, this.formEndpoint, this.resourceId, this.formHttpMethod)
      .pipe(
        finalize(() => this.inFlight = false)
      )
      .subscribe(
        (formResource:HalSource) => {
          this.submitted.emit(formResource);
          this.showNotifications && this.showSuccessNotification();
        },
        (error:IOPFormErrorResponse) => {
          this.errored.emit(error);
          this.showNotifications && this._notificationsService.addError(this.text.validation_error_message);
        },
      );
  }

  private showSuccessNotification():void {
    let submit_message = this.resourceId ? this.text.successful_update : this.text.successful_create;
    this._notificationsService.addSuccess(submit_message);
  }

  validateForm() {
    if (!this.formEndpoint) {
      throw new Error(this.noPathToSubmitToError);
    }

    this._formsService.validateForm$(this.form, this.formEndpoint).subscribe();
  }

  private _initializeDynamicForm(
    settings?:IOPFormSettings,
    resourcePath?:string,
    resourceId?:string,
    formUrl?:string,
    payload?:Object,
  ) {
    if (settings) {
      this._setupDynamicFormFromSettings();
    } else {
      const newFormEndPoint = this._getFormEndPoint(formUrl, resourcePath);

      if (newFormEndPoint && newFormEndPoint !== this.formEndpoint) {
        this.formEndpoint = newFormEndPoint;
        this._setupDynamicFormFromBackend(this.formEndpoint, resourceId, payload);
      } else if (!newFormEndPoint) {
        console.error(this.noSettingsSourceErrorMessage);
      }
    }
  }

  private _getFormEndPoint(formUrl?:string, resourcePath?:string): string | null {
    let formEndpoint;

    if (formUrl) {
      formEndpoint = formUrl.endsWith(`/form`) ?
        formUrl.replace(`/form`, ``) :
        formUrl;
    } else if (resourcePath) {
      formEndpoint = `${this._pathHelperService.api.v3.apiV3Base}${resourcePath}`;
    } else {
      formEndpoint = null;
    }

    return formEndpoint;
  }

  private _setupDynamicFormFromBackend(formEndpoint?:string, resourceId?:string, payload?:Object) {
    this._dynamicFormService
      .getSettingsFromBackend$(formEndpoint, resourceId, payload)
      .pipe(
        catchError(error => {
          this._notificationsService.addError(this.text.load_error_message);
          throw error;
        })
      )
      .subscribe(dynamicFormSettings => this._setupDynamicForm(dynamicFormSettings));
  }

  private _setupDynamicFormFromSettings() {
    const formattedSettings:IOPFormSettingsResource = {
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
    this.innerModel = model;

    this._changeDetectorRef.detectChanges();

    if (!this.isStandaloneForm) {
      this.onChange(this.innerModel);
    }
  }
}
