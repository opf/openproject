import { HttpClient } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { FormGroup } from "@angular/forms";
import { FormlyForm } from "@ngx-formly/core";
import { Observable } from "rxjs";
import { map } from "rxjs/operators";
import { IOPDynamicFormSettings } from "../../typings";
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

  getSettingsFromBackend$(url:string): Observable<IOPDynamicFormSettings>{
    return this._httpClient
      .post<IOPFormSettings>(
        url,
        {},
        {
          withCredentials: true,
          responseType: 'json'
        }
      )
      .pipe(
        map((formConfig => this.getSettings(formConfig))),
      );
  }

  getSettings(formConfig:IOPFormSettings):IOPDynamicFormSettings {
    const formSchema = formConfig._embedded?.schema;
    const formPayload = formConfig._embedded?.payload;
    const dynamicForm = {
      fields: this._dynamicFieldsService.getConfig(formSchema, formPayload),
      model: this._dynamicFieldsService.getModel(formSchema, formPayload),
      form: new FormGroup({}),
    };

    return dynamicForm;
  }

  submit$(form:FormGroup, resourceEndpoint:string, resourceId?:string) {
    return this._formsService.submit$(form, resourceEndpoint, resourceId);
  }
}