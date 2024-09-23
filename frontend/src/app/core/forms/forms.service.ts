import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { UntypedFormGroup } from '@angular/forms';
import { catchError, map } from 'rxjs/operators';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class FormsService {
  constructor(
    private _httpClient:HttpClient,
  ) { }

  submit$(form:UntypedFormGroup, resourceEndpoint:string, resourceId?:string, formHttpMethod?:'post' | 'patch', formSchema?:IOPFormSchema):Observable<any> {
    const modelToSubmit = this.formatModelToSubmit(form.getRawValue(), formSchema);
    const httpMethod = resourceId ? 'patch' : (formHttpMethod || 'post');
    const url = resourceId ? `${resourceEndpoint}/${resourceId}` : resourceEndpoint;

    return this._httpClient
      [httpMethod](
        url,
        modelToSubmit,
        {
          withCredentials: true,
          responseType: 'json',
        },
      )
      .pipe(
        catchError((error:HttpErrorResponse) => {
          if (error.status == 422) {
            this.handleBackendFormValidationErrors(error, form);
          }

          throw error;
        }),
      );
  }

  validateForm$(form:UntypedFormGroup, resourceEndpoint:string, formSchema?:IOPFormSchema):Observable<any> {
    const modelToSubmit = this.formatModelToSubmit(form.value, formSchema);

    return this._httpClient
      .post(
        `${resourceEndpoint}/form`,
        modelToSubmit,
        {
          withCredentials: true,
          responseType: 'json',
        },
      )
      .pipe(
        map((response:HalSource) => this.getFormattedErrors(Object.values(response?._embedded?.validationErrors))),
        map((formattedErrors:IFormattedValidationError[]) => this.setFormValidationErrors(formattedErrors, form)),
      );
  }

  /** HAL resources formatting
   * The backend form model/payload contains HAL resources nested in the '_links' property.
   * In order to simplify its use, the model is flatted and HAL resources are placed at
   * the first level of the model with the 'formatModelToEdit' method.
   * 'formatModelToSubmit' places HAL resources model back to the '_links' property and formats them
   * in the shape of '{href:hrefValue}' in order to fit the backend expectations.
   * */
  private formatModelToSubmit(formModel:IOPFormModel, formSchema:IOPFormSchema = {}):IOPFormModel {
    let { _links: linksModel, ...mainModel } = formModel;
    const resourcesModel = linksModel || Object.keys(formSchema)
      .filter((formSchemaKey) => !!formSchema[formSchemaKey]?.type && formSchema[formSchemaKey]?.location === '_links')
      .reduce((result, formSchemaKey) => {
        const { [formSchemaKey]: keyToRemove, ...mainModelWithoutResource } = mainModel;
        mainModel = mainModelWithoutResource;

        return { ...result, [formSchemaKey]: formModel[formSchemaKey] };
      }, {});

    const formattedResourcesModel = Object
      .keys(resourcesModel)
      .reduce((result, resourceKey) => {
        // @ts-ignore
        const resourceModel = resourcesModel[resourceKey];
        // Form.payload resources have a HalLinkSource interface while
        // API resource options have a IAllowedValue interface
        const formattedResourceModel = Array.isArray(resourceModel)
          ? resourceModel.map((resourceElement) => ({ href: resourceElement?.href || resourceElement?._links?.self?.href || null }))
          : { href: resourceModel?.href || resourceModel?._links?.self?.href || null };

        return {
          ...result,
          [resourceKey]: formattedResourceModel,
        };
      }, {});

    return {
      ...mainModel,
      _links: formattedResourcesModel,
    };
  }

  /** HAL resources formatting
   * The backend form model/payload contains HAL resources nested in the '_links' property.
   * In order to simplify its use, the model is flatted and HAL resources are placed at
   * the first level of the model. 'NonValue' values are also removed from the model so
   * default values from the DynamicForm are set.
   */
  formatModelToEdit(formModel:IOPFormModel = {}):IOPFormModel {
    const { _links: resourcesModel, _meta: metaModel, ...otherElements } = formModel;
    const otherElementsModel = Object.keys(otherElements)
      .filter((key) => this.isValue(otherElements[key]))
      .reduce((model, key) => ({ ...model, [key]: otherElements[key] }), {});

    const model = {
      ...otherElementsModel,
      _meta: metaModel,
      ...this.getFormattedResourcesModel(resourcesModel),
    };

    return model;
  }

  private handleBackendFormValidationErrors(error:HttpErrorResponse, form:UntypedFormGroup):void {
    const errors:IOPFormError[] = error?.error?._embedded?.errors
      ? error?.error?._embedded?.errors : [error.error];
    const formErrors = this.getFormattedErrors(errors);

    this.setFormValidationErrors(formErrors, form);
  }

  private setFormValidationErrors(errors:IFormattedValidationError[], form:UntypedFormGroup) {
    errors.forEach((err:any) => {
      const formControl = form.get(err.key) || form.get('_links')?.get(err.key);

      formControl?.setErrors({ [err.key]: { message: err.message } });
    });
  }

  private getAllFormValidationErrors(validationErrors:IOPValidationErrors, formControlKeys?:string | string[]):{ [key:string]:{ message:string } } {
    const errors = Object.values(validationErrors);
    const keysToValidate = Array.isArray(formControlKeys) ? formControlKeys : [formControlKeys];
    const formErrors = this.getFormattedErrors(errors)
      .filter((error) => {
        if (!formControlKeys) {
          return true;
        }
        return keysToValidate.includes(error.key);
      })
      .reduce((result, { key, message }) => ({
        ...result,
        [key]: { message },
      }), {});

    return formErrors;
  }

  private getFormattedErrors(errors:IOPFormError[]):IFormattedValidationError[] {
    const formattedErrors = errors.map((err) => ({
      key: err._embedded.details.attribute,
      message: err.message,
    }));

    return formattedErrors;
  }

  private getFormattedResourcesModel(resourcesModel:IOPFormModel['_links'] = {}):IOPFormModel['_links'] {
    return Object.keys(resourcesModel).reduce((result, resourceKey) => {
      const resource = resourcesModel[resourceKey];
      // ng-select needs a 'name' in order to show the label
      // We need to add it in case of the form payload (HalLinkSource)
      const resourceModel = Array.isArray(resource)
        ? resource.map((resourceElement) => ({ ...resourceElement, name: resourceElement?.name || resourceElement?.title }))
        : { ...resource, name: resource?.name || resource?.title };

      result = {
        ...result,
        ...(this.isValue(resourceModel) && { [resourceKey]: resourceModel }),
      };

      return result;
    }, {});
  }

  private isValue(value:any) {
    return ![null, undefined, ''].includes(value);
  }
}
