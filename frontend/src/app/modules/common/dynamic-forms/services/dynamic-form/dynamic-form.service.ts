import { HttpClient, HttpErrorResponse } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { FormGroup } from "@angular/forms";
import { FormlyForm } from "@ngx-formly/core";
import { Observable } from "rxjs";
import {
  catchError,
  map,
} from "rxjs/operators";
import {
  IOPDynamicFormSettings,
  IOPFormSettings,
  IOPFormModel,
  IOPFormError,
} from "../../typings";
import { DynamicFieldsService } from "core-app/modules/common/dynamic-forms/services/dynamic-fields/dynamic-fields.service";
@Injectable()
export class DynamicFormService {
  dynamicForm:FormlyForm;

  constructor(
    private _httpClient:HttpClient,
    private _dynamicFieldsService:DynamicFieldsService,
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

  submit$(formModel:IOPFormModel, resourceEndpoint:string, resourceId?:string) {
    const modelToSubmit = this._formatModelToSubmit(formModel);
    const httpMethod = resourceId ? 'patch' : 'post';
    const url = resourceId ? `${resourceEndpoint}/${resourceId}` : resourceEndpoint;

    return this._httpClient
      [httpMethod](
        url,
        modelToSubmit,
        {
          withCredentials: true,
          responseType: 'json'
        }
      )
      .pipe(
        catchError((error:HttpErrorResponse) => {
          this._handleFormErrors(error, this.dynamicForm.form as FormGroup);

          throw error;
        })
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

  private _formatModelToSubmit(formModel:IOPFormModel) {
    const resources = formModel._links || {};
    const formattedResources = Object
      .keys(resources)
      .reduce((result, resourceKey) => {
        const resource = resources[resourceKey];
        // Form.payload resources have a HalLinkSource interface while
        // API resource options have a IAllowedValue interface
        const resourceValue = Array.isArray(resource) ?
          resource.map(resourceElement => ({ href: resourceElement?.href || resourceElement?._links?.self?.href })) :
          { href: resource?.href || resource?._links?.self?.href };

        return { [resourceKey]: resourceValue };
      }, {});

    return {
      ...formModel,
      _links: formattedResources,
    }
  }

  private _handleFormErrors(error:HttpErrorResponse, form:FormGroup) {
    if (error.status == 422) {
      const errors:IOPFormError[] = error.error._embedded.errors ?
        error.error._embedded.errors : [error.error];

      errors.forEach((err:any) => {
        const key = err._embedded.details.attribute;
        const message = err.message;
        const formControl = form.get(key)!;

        formControl.setErrors({[key]: {message}});
      });
    }
  }
}