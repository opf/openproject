import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { UntypedFormGroup } from '@angular/forms';
import { FormlyForm } from '@ngx-formly/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { DynamicFieldsService } from 'core-app/shared/components/dynamic-forms/services/dynamic-fields/dynamic-fields.service';
import { FormsService } from 'core-app/core/forms/forms.service';
import { IOPDynamicFormSettings } from '../../typings';

@Injectable()
export class DynamicFormService {
  dynamicForm:FormlyForm;

  formSchema:IOPFormSchema;

  constructor(
    private _httpClient:HttpClient,
    private _dynamicFieldsService:DynamicFieldsService,
    private _formsService:FormsService,
  ) {}

  registerForm(dynamicForm:FormlyForm) {
    this.dynamicForm = dynamicForm;
  }

  getSettingsFromBackend$(formEndpoint?:string, resourceId?:string, payload:Object = {}):Observable<IOPDynamicFormSettings> {
    const resourcePath = resourceId ? `/${resourceId}` : '';
    const formPath = formEndpoint?.endsWith('/form') ? '' : '/form';
    const url = `${formEndpoint}${resourcePath}${formPath}`;

    return this._httpClient
      .post<IOPFormSettingsResource>(
      url,
      payload,
      {
        withCredentials: true,
        responseType: 'json',
      },
    )
      .pipe(
        map(((formConfig) => this.getSettings(formConfig))),
      );
  }

  getSettings(formConfig:IOPFormSettingsResource):IOPDynamicFormSettings {
    this.formSchema = formConfig._embedded?.schema;
    const formPayload = formConfig._embedded?.payload;
    const dynamicForm = {
      form: new UntypedFormGroup({}),
      fields: this._dynamicFieldsService.getConfig(this.formSchema, formPayload),
      model: this._dynamicFieldsService.getModel(formPayload),
    };

    return dynamicForm;
  }

  formatModelToEdit(formModel:IOPFormModel):IOPFormModel {
    return this._formsService.formatModelToEdit(formModel);
  }

  validateForm$(form:UntypedFormGroup, resourceEndpoint:string) {
    return this._formsService.validateForm$(form, resourceEndpoint, this.formSchema);
  }

  submit$(form:UntypedFormGroup, resourceEndpoint:string, resourceId?:string, formHttpMethod?:'post' | 'patch') {
    return this._formsService.submit$(form, resourceEndpoint, resourceId, formHttpMethod, this.formSchema);
  }
}
