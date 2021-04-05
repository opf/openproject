import { HttpClient, HttpErrorResponse } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { FormGroup } from "@angular/forms";
import { FormlyFieldConfig, FormlyForm } from "@ngx-formly/core";
import { Observable, of } from "rxjs";
import {
  catchError,
  map,
} from "rxjs/operators";
import {
  IOPDynamicForm,
  IFieldSchemaWithKey,
  IOPForm,
  IAttributeGroup,
  IOPFormSchema,
  IFormModel,
  IFieldTypeMap,
  IOPFormlyFieldConfig,
  IFormError,
  IFieldSchema,
} from "../typings";
@Injectable()
export class DynamicFormService {
  dynamicForm:FormlyForm;

  constructor(
    private _httpClient:HttpClient,
  ) {}

  registerForm(dynamicForm:FormlyForm) {
    this.dynamicForm = dynamicForm;
  }

  getForm$(url:string): Observable<IOPDynamicForm>{
    return this._httpClient
      .post<IOPForm>(
        url,
        {},
        {
          withCredentials: true,
          responseType: 'json'
        }
      )
      .pipe(
        map((formConfig => this._getDynamicForm(formConfig))),
      )
  }

  submitForm$(formModel:IFormModel, resourceEndpoint:string, resourceId?:string) {
    const modelToSubmit = this._formatModelToSubmit(formModel);
    const httpMethod = resourceId ? 'patch' : 'post';
    // TODO: Does this work for every resource type?
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

  private _getDynamicForm(formConfig:IOPForm):IOPDynamicForm {
    const formSchema = formConfig._embedded?.schema;
    const formModel = formConfig._embedded?.payload;
    const formFieldGroups = formSchema._attributeGroups;
    const fieldSchemas = this._getFieldsSchemas(formSchema, formModel);  
    const fieldsModel = this._getFieldsModel(fieldSchemas, formModel);
    const formlyFields = fieldSchemas.map(fieldSchema => this._getFormlyFieldConfig(fieldSchema));
    const formlyFormWithFieldGroups = this._getFormlyFormWithFieldGroups(formFieldGroups, formlyFields);
    const dynamicForm = {
      fields: formlyFormWithFieldGroups,
      model: fieldsModel,
      form: new FormGroup({}),
    };

    return dynamicForm;
  }

  private _getFieldsSchemas(formSchema:IOPFormSchema, formModel:IFormModel):IFieldSchemaWithKey[] {
    return Object.keys(formSchema)
      .map(schemaKey => {
        const schemaValue = {
          ...formSchema[schemaKey],
          key: formModel?._links && schemaKey in formModel._links ?
            `_links.${schemaKey}` :
            schemaKey
        };

        return schemaValue;
      })
      .filter(schemaValue => this._isFieldSchema(schemaValue));
  }

  // TODO: Is there a better way to check this?
  private _isFieldSchema(schemaValue:IFieldSchemaWithKey | any):boolean {
    return schemaValue?.type &&
      schemaValue?.name != null &&
      schemaValue?.required != null &&
      schemaValue?.hasDefault != null &&
      schemaValue?.writable != null;
  }

  private _getFieldsModel(fieldSchemas:IFieldSchemaWithKey[], formModel:IFormModel = {}) {
    // TODO: Handle Formattable and time types?
    const {_links:resourcesModel, ...otherElementsModel} = formModel;
    const model = {
      ...otherElementsModel,
      _links: this._getFormattedResourcesModel(resourcesModel),
    }

    return model;
  }

  private _getFormattedResourcesModel(resourcesModel:IFormModel['_links'] = {}){
    return Object.keys(resourcesModel).reduce((result, resourceKey) => {
      const resource = resourcesModel[resourceKey];
      const resourceModel = Array.isArray(resource) ?
        resource.map(resourceElement => resourceElement?.href && { ...resourceElement, name: resourceElement?.title }) :
        resource?.href && { ...resource, name: resource?.title };

      result = {
        ...result,
        [resourceKey]: resourceModel,
      }

      return result;
    }, {});
  }

  private _getFormlyFieldConfig(field:IFieldSchemaWithKey):IOPFormlyFieldConfig {
    // TODO: Do we want to localize labels?
    const {key, name:label, required, writable} = field;
    const {templateOptions, ...fieldTypeConfig} = this._getFieldTypeConfig(field);
    const fieldOptions = this._getFieldOptions(field);
    const formlyFieldConfig = {
      ...fieldTypeConfig,
      key,
      className: `op-form--field ${fieldTypeConfig.className}`,
      templateOptions: {
        required,
        label,
        disabled: !writable,
        ...templateOptions,
        ...fieldOptions && {options: fieldOptions},
      },
    }

    return formlyFieldConfig;
  }

  private _getFieldTypeConfig(field:IFieldSchemaWithKey):FormlyFieldConfig {
    const inputTypeMap = {
      text: {
        type: 'textInput',
        // TODO: Should we keep this hardcode?
        focus: field.name === 'subject',
        className: 'inline-edit--field',
        templateOptions: {
          type: 'text',
        },
      },
      integer: {
        type: 'integerInput',
        className: `inline-edit--field ${field.name}`,
        templateOptions: {
          type: 'number',
          locale: I18n.locale,
        },
      },
      boolean: {
        type: 'booleanInput',
        className: `inline-edit--field inline-edit--boolean-field`,
        templateOptions: {
          type: 'checkbox',
        },
      },
      date: {
        type: 'dateInput',
        className: `inline-edit--field`,
      },
      formattable: {
        type: 'formattableInput',
        className: `textarea-wrapper`,
        templateOptions: {
          // TODO: Get rtl this from the schema
          rtl: false,
          name: field.name,
          editorType: 'full',
          inlineLabel: true,
        },
      },
      select: {
        type: 'selectInput',
        className: `inline-edit--field ${field.name}`,
        templateOptions: {
          type: 'number',
          locale: I18n.locale,
          multiple: field.key.replace('_links.', '').startsWith('[]'),
          bindLabel: 'title',
          searchable: false,
          virtualScroll: true,
          typeahead: false,
          clearOnBackspace: false,
          clearSearchOnAdd: false,
          hideSelected: false,
          text: {
            add_new_action: I18n.t('js.label_create'),
          },
        },
        expressionProperties: {
          'templateOptions.clearable': (model: any, formState: any, field: FormlyFieldConfig) => !field.templateOptions?.required,
        },
      },
    }
    const fieldTypeMap:IFieldTypeMap = {
      Integer: inputTypeMap.integer,
      String: inputTypeMap.text,
      Priority: inputTypeMap.select,
      Status: inputTypeMap.select,
      Type: inputTypeMap.select,
      User: inputTypeMap.select,
      Version: inputTypeMap.select,
      TimeEntriesActivity: inputTypeMap.select,
      Category: inputTypeMap.select,
      CustomOption: inputTypeMap.select,
      Project: inputTypeMap.select,
      ProjectStatus: inputTypeMap.select,
      Boolean: inputTypeMap.boolean,
      Date: inputTypeMap.date,
      Formattable: inputTypeMap.formattable,
      // TODO: Do we have DateTime input?
      DateTime: inputTypeMap.date,
    }

    return fieldTypeMap[field.type];
  }

  private _getFieldOptions(field:IFieldSchemaWithKey) {
    const allowedValues = field._embedded?.allowedValues || field._links?.allowedValues;

    // TODO: Check why is this
    if (!allowedValues) {
      return;
    }

    return Array.isArray(allowedValues) ?
      of(allowedValues) :
      this._httpClient
            .get(allowedValues!.href)
            .pipe(
              map((response: api.v3.Result) => response._embedded.elements),
              // TODO: Handle the Status options (currently void)
              map(options => options.map((option:IFieldSchema['options']) => ({...option, title: option._links?.self?.title})))
            );
  }

  private _getFormlyFormWithFieldGroups(fieldGroups:IAttributeGroup[] = [], formFields:IOPFormlyFieldConfig[] = []) {
    // TODO: Handle sort fields in schema order
    // TODO: Handle nested groups?
    // TODO: Handle form fields with integer key?
    const fieldGroupKeys = fieldGroups.reduce((groupKeys, fieldGroup) => [...groupKeys, ...fieldGroup.attributes], []);
    const fomFieldsWithoutGroup = formFields.filter(formField => {
      const formFieldKey = formField.key?.split('.')?.pop();

      return formFieldKey ?
        !fieldGroupKeys.includes(formFieldKey) :
        true;
    });
    const formFieldGroups = fieldGroups.reduce((formWithFieldGroups: IOPFormlyFieldConfig[], fieldGroup) => {
      const newFormFieldGroup = {
        wrappers: ['op-form-field-group-wrapper'],
        fieldGroupClassName: 'op-form--field-group',
        templateOptions: {
          label: fieldGroup.name,          
        },
        fieldGroup: formFields.filter(formField => {
          const formFieldKey = formField.key?.split('.')?.pop();

          return formFieldKey ?
            fieldGroup.attributes.includes(formFieldKey) :
            false;
        }),
      }

      if (newFormFieldGroup.fieldGroup.length) {
        formWithFieldGroups = [...formWithFieldGroups, newFormFieldGroup];
      }      

      return formWithFieldGroups;
    }, []);

    return [...fomFieldsWithoutGroup, ...formFieldGroups];
  }

  private _formatModelToSubmit(formModel:IFormModel) {
    const resources = formModel._links || {};
    const formattedResources = Object
      .keys(resources)
      .reduce((result, resourceKey) => {
        const resource = resources[resourceKey];
        const resourceValue = Array.isArray(resource) ?
          resource.map(resourceElement => ({ href: resourceElement?._links!.self.href })) :
          { href: resource?._links!.self.href };

        return { [resourceKey]: resourceValue };
      }, {});

    return {
      ...formModel,
      _links: formattedResources,
    }
  }

  private _handleFormErrors(error:HttpErrorResponse, form:FormGroup) {
    // TODO: How do we handle other form errors?
    if (error.status == 422) {
      const errors:IFormError[] = error.error._embedded.errors ?
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