import { HttpClient } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { FormGroup } from "@angular/forms";
import { FormlyFieldConfig, FormlyForm } from "@ngx-formly/core";
import { Observable, of, ReplaySubject } from "rxjs";
import {
  catchError,
  map,
  switchMap,
} from "rxjs/operators";
import {
  IDynamicForm,
  IFieldSchemaWithKey,
  IOPForm,
  IAttributeGroup,
  IOPFormSchema,
  IFormModel,
  IFieldTypeMap,
  IOPFormlyFieldConfig,
} from "../typings";
import { ErrorResource } from "core-app/modules/hal/resources/error-resource";

@Injectable()
export class DynamicFormService {
  form:FormlyForm;
  formId:string;
  projectId:string;
  typeHref:string;
  errors:{[key:string]:string} = {};

  private _form = new ReplaySubject<IDynamicForm>(1);
  readonly form$:Observable<IDynamicForm> = this._form.asObservable();

  constructor(
    private httpClient:HttpClient,
  ) {}

  registerForm(formlyForm:FormlyForm) {
    if (!formlyForm) { return; }

    this.form = formlyForm;
  }

  // TODO: Implement passing the params and lockVersion
  getForm$(typeHref = this.typeHref, formId = this.formId, projectId = this.projectId): Observable<IDynamicForm>{
    this.formId = formId;
    this.projectId = projectId;
    this.typeHref = typeHref;

    // TODO: Replace with dynamic url
    let url = '/api/v3/projects/form';

    return this.httpClient
      .post<IOPForm>(
        url,
        {},
        {
          withCredentials: true,
          responseType: 'json'
        }
      )
      .pipe(
        map((formConfig => {
          const formlyForm = this._getFormlyForm(formConfig);

          this._form.next(formlyForm);
        })),
        switchMap(() => this.form$)
      )
  }

  private _getFormlyForm(formConfig:IOPForm):IDynamicForm {
    const formSchema = formConfig._embedded?.schema;
    const formModel = formConfig._embedded?.payload;
    const formFieldGroups = formSchema._attributeGroups;
    const fieldSchemas = this._getFieldsSchemas(formSchema, formModel);  
    const fieldsModel = this._getFieldsModel(fieldSchemas, formModel);
    const formlyFields = fieldSchemas.map(fieldSchema => this._getFormlyFieldConfig(fieldSchema));
    const formlyFormWithFieldGroups = this._getFormlyFormWithFieldGroups(formFieldGroups, formlyFields);
    const formlyForm = {
      fields: formlyFormWithFieldGroups,
      model: fieldsModel,
    };

    console.log('formlyForm', formlyForm)

    return formlyForm;
  }

  // TODO: Is there a better way to check this?
  private _isFieldSchema(schemaValue:IFieldSchemaWithKey | any):boolean {
    return schemaValue?.type &&
      schemaValue?.name != null &&
      schemaValue?.required != null &&
      schemaValue?.hasDefault != null &&
      schemaValue?.writable != null;
  }

  private _getFieldsSchemas(formSchema:IOPFormSchema, formModel:IFormModel):IFieldSchemaWithKey[] {
    return Object.keys(formSchema)
      .map(schemaKey => {
        const schemaValue = {
          ...formSchema[schemaKey],
          key: formModel?._links && formModel?._links[schemaKey] ?
            `_links.${schemaKey}` :
            schemaKey
        };

        return schemaValue;
      })
      .filter(schemaValue => this._isFieldSchema(schemaValue));
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
      }
    }

    return formlyFieldConfig;
  }

  private _getFieldTypeConfig(field:IFieldSchemaWithKey):FormlyFieldConfig {
    const inputTypeMap = {
      text: {
        type: 'textInput',
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
        },
      },
      select: {
        type: 'selectInput',
        className: `inline-edit--field ${field.name}`,
        templateOptions: {
          type: 'number',
          locale: I18n.locale,
          multiple: false,
          bindLabel: 'name',
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
      // TODO: Replace with Duration component
      Duration: {
        type: 'input',
        templateOptions: {
          type: 'number'
        },
      },
      Collection: {
        type: 'input',
      },
      "[]CustomOption": {
        type: 'op-select',
        templateOptions: {
          multiple: true
        },
      }
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
      this.httpClient
            .get(allowedValues!.href)
            .pipe(
              map((response: api.v3.Result) => response._embedded.elements)
            );
  }

  private _getFieldsModel(fieldSchemas:IFieldSchemaWithKey[], formModel:IFormModel = {}) {
    // TODO: Handle Formattable and time types
    const {_links:resourcesModel, ...otherElementsModel} = formModel;
    const model = {
      ...otherElementsModel,
      _links: this._getFormattedResourcesModel(resourcesModel),
    }
    
    return model;
  }

  private _getFormattedResourcesModel(resourcesModel:IFormModel['_links'] = {}){
    return Object.keys(resourcesModel).reduce((result, resourceKey) => {
      // TODO: Fix this typing
      // Some customfields come with an [] as value
      const resourceModel = resourcesModel[resourceKey]?.href ? resourcesModel[resourceKey] : null;

      result = {
        ...result,
        [resourceKey]: resourceModel && {
          ...resourceModel,
          ...{name: resourceModel?.title},
        }
      }

      return result;
    }, {});
  }

  private _getFormlyFormWithFieldGroups(fieldGroups:IAttributeGroup[] = [], formFields:IOPFormlyFieldConfig[] = []) {
    // TODO: Handle nested groups
    // TODO: Handle sort fields in schema order
    // TODO: Handle form fields with integer key
    const fieldGroupKeys = fieldGroups.reduce((groupKeys, fieldGroup) => [...groupKeys, ...fieldGroup.attributes], []);
    const fomFieldsWithoutGroup = formFields.filter(formField => {
      const formFieldKey = formField.key?.split('.')?.pop();

      return formFieldKey ?
        !fieldGroupKeys.includes(formFieldKey) :
        true;
      //!fieldGroupKeys.includes(formField.key?.split('.')?.pop())
    })
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

  saveForm(formModel:IFormModel) {
    // TODO: Replace with dynamic url
    const url = '/api/v3/projects';
    const modelToSubmit = this.formatModelToSubmit(formModel);

    return this.httpClient
                .post(
                  url,
                  modelToSubmit,
                  {
                    withCredentials: true,
                    responseType: 'json'
                  }
                )
                .pipe(
                  catchError((error:ErrorResource) => {
                    this.handleFormErrors(error, this.form.form as FormGroup);

                    throw error;
                  })
                );
  }

  formatModelToSubmit(formModel:IFormModel) {
    const resources = formModel._links || {};
    const formattedResources = Object
      .keys(resources)
      .reduce((result, resourceKey) => {
        const resource = resources[resourceKey];
        const resourceValue = Array.isArray(resource) ?
          resource.map(resourceElement => ({ href: resourceElement?._links.self.href })) :
          { href: resource?._links.self.href };

        return { [resourceKey]: resourceValue };
      }, {});

    return {
      ...formModel,
      _links: formattedResources,
    }
  }

  handleFormErrors(error:ErrorResource, form:FormGroup) {
    if (error.status == 422) {
      form.markAllAsTouched();
      const errors = error.error._embedded.errors;

      errors.forEach((err:any) => {
        const key = err._embedded.details.attribute;
        const message = err.message;

        form.get(key)!.setErrors({[key]: {message}})
      })
    }
  }
}