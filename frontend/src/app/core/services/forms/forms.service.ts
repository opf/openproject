import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from "@angular/common/http";
import { FormGroup } from "@angular/forms";
import { catchError } from "rxjs/operators";
import { Observable } from "rxjs";

@Injectable({
  providedIn: 'root'
})
export class FormsService {

  constructor(
    private _httpClient:HttpClient,
  ) { }

  submit$(form:FormGroup, resourceEndpoint:string, resourceId?:string):Observable<any> {
    const modelToSubmit = this._formatModelToSubmit(form.value);
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
          this._handleFormErrors(error, form);

          throw error;
        })
      );
  }

  private _formatModelToSubmit(formModel:IOPFormModel):IOPFormModel {
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

        return {
          ...result,
          [resourceKey]: resourceValue,
        };
      }, {});

    return {
      ...formModel,
      _links: formattedResources,
    }
  }

  private _handleFormErrors(error:HttpErrorResponse, form:FormGroup):void {
    if (error.status == 422) {
      const errors:IOPFormError[] = error?.error?._embedded?.errors ?
        error?.error?._embedded?.errors : [error.error];

      errors.forEach((err:any) => {
        const key = err._embedded.details.attribute;
        const message = err.message;
        const formControl = form.get(key) || form.get('_links')?.get(key);

        formControl?.setErrors({[key]: {message}});
      });
    }
  }
}
