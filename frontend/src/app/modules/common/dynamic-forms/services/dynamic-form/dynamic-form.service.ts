import { HttpClient } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { FormGroup } from "@angular/forms";
import { FormlyForm } from "@ngx-formly/core";
import { Observable } from "rxjs";
import {
  map,
} from "rxjs/operators";
import {
  IOPDynamicFormSettings,
} from "../../typings";
import { DynamicFieldsService } from "core-app/modules/common/dynamic-forms/services/dynamic-fields/dynamic-fields.service";
import { FormsService } from "core-app/core/services/forms/forms.service";
@Injectable()
export class DynamicFormService {
  dynamicForm:FormlyForm;

  constructor(
    private _httpClient:HttpClient,
    private _dynamicFieldsService:DynamicFieldsService,
    private _formsService:FormsService,
  ) {}

  registerForm(dynamicForm:FormlyForm) {
    this.dynamicForm = dynamicForm;
  }

  getSettingsFromBackend$(formEndpoint?:string, resourceId?:string, payload:Object = {}):Observable<IOPDynamicFormSettings>{
    const resourcePath = resourceId ? `/${resourceId}` : '';
    const formPath = formEndpoint?.endsWith('/form') ? '' : '/form';
    const url = `${formEndpoint}${resourcePath}${formPath}`;

    return this._httpClient
      .post<IOPFormSettingsResource>(
        url,
        payload,
        {
          withCredentials: true,
          responseType: 'json'
        }
      )
      .pipe(
        map((formConfig => this.getSettings(formConfig))),
      );
  }

  getSettings(formConfig:IOPFormSettingsResource):IOPDynamicFormSettings {
    const formSchema = formConfig._embedded?.schema;
    const formPayload = formConfig._embedded?.payload;
    const dynamicForm = {
      fields: this._dynamicFieldsService.getConfig(formSchema, formPayload),
      model: this._dynamicFieldsService.getModel(formPayload),
      form: new FormGroup({}),
    };

    return dynamicForm;
  }

  submit$(form:FormGroup, resourceEndpoint:string, resourceId?:string, formHttpMethod?: 'post' | 'patch') {
    return this._formsService.submit$(form, resourceEndpoint, resourceId, formHttpMethod);
  }
}