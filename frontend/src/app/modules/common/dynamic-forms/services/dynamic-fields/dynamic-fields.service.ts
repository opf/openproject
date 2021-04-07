import { Injectable } from '@angular/core';
import {
  IAttributeGroup,
  IDynamicInputConfig,
  IFieldSchema,
  IFieldSchemaWithKey,
  IOPFormlyFieldConfig,
  IOPFormModel,
  IOPFormSchema,
} from "../../typings";
import { FormlyFieldConfig } from "@ngx-formly/core";
import { of } from "rxjs";
import { map } from "rxjs/operators";
import { HttpClient } from "@angular/common/http";


@Injectable()
export class DynamicFieldsService {
  readonly inputsCatalogue:IDynamicInputConfig[] = [
    {
      config: {
        type: 'textInput',
        className: 'inline-edit--field',
        templateOptions: {
          type: 'text',
        },
      },
      useForFields: ['String']
    },
    {
      config: {
        type: 'integerInput',
        className: `inline-edit--field`,
        templateOptions: {
          type: 'number',
          locale: I18n.locale,
        },
      },
      useForFields: ['Integer']
    },
    {
      config: {
        type: 'booleanInput',
        className: `inline-edit--field inline-edit--boolean-field`,
        templateOptions: {
          type: 'checkbox',
        },
      },
      useForFields: ['Boolean']
    },
    {
      config: {
        type: 'dateInput',
        className: `inline-edit--field`,
      },
      useForFields: ['Date', 'DateTime']
    },
    {
      config: {
        type: 'formattableInput',
        className: `textarea-wrapper`,
        templateOptions: {
          editorType: 'full',
          inlineLabel: true,
        },
      },
      useForFields: ['Formattable']
    },
    {
      config: {
        type: 'selectInput',
        className: `inline-edit--field`,
        templateOptions: {
          type: 'number',
          locale: I18n.locale,
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
          'templateOptions.clearable': (model:any, formState:any, field:FormlyFieldConfig) => !field.templateOptions?.required,
          'templateOptions.multiple': (model:any, formState:any, field:FormlyFieldConfig) => (field.key! as string).replace('_links.', '').startsWith('[]'),
        },
      },
      useForFields: ['Priority', 'Status', 'Type', 'User', 'Version', 'TimeEntriesActivity', 'Category', 'CustomOption', 'Project', 'ProjectStatus']
    },
  ]

  constructor(
    private _httpClient:HttpClient,
  ) { }

  getConfig(formSchema:IOPFormSchema, formPayload:IOPFormModel):IOPFormlyFieldConfig[] {
    const formFieldGroups = formSchema._attributeGroups;
    const fieldSchemas = this._getFieldsSchemasWithKey(formSchema, formPayload);
    const formlyFields = fieldSchemas.map(fieldSchema => this._getFormlyFieldConfig(fieldSchema));
    const formlyFormWithFieldGroups = this._getFormlyFormWithFieldGroups(formFieldGroups, formlyFields);

    return formlyFormWithFieldGroups;
  }

  getModel(formSchema:IOPFormSchema, formPayload:IOPFormModel):IOPFormModel {
    const fieldSchemas = this._getFieldsSchemasWithKey(formSchema, formPayload);
    const fieldsModel = this._getFieldsModel(fieldSchemas, formPayload);

    return fieldsModel;
  }

  private _getFieldsSchemasWithKey(formSchema:IOPFormSchema, formModel:IOPFormModel):IFieldSchemaWithKey[] {
    return Object.keys(formSchema)
      .map(fieldSchemaKey => {
        const fieldSchema = {
          ...formSchema[fieldSchemaKey],
          key: this._isResourceSchema(fieldSchemaKey, formModel) ?
            `_links.${fieldSchemaKey}` :
            fieldSchemaKey
        };

        return fieldSchema;
      })
      .filter(fieldSchema => this._isFieldSchema(fieldSchema) && fieldSchema.writable);
  }

  // TODO: Adapt to the new API (schema.parent?.location === '_links')
  private _isResourceSchema(fieldSchemaKey:string, formModel:IOPFormModel):boolean {
    return !!(formModel?._links && fieldSchemaKey in formModel._links);
  }

  private _isFieldSchema(schemaValue:IFieldSchemaWithKey | any):boolean {
    return schemaValue?.type;
  }

  private _getFieldsModel(fieldSchemas:IFieldSchemaWithKey[], formModel:IOPFormModel = {}):IOPFormModel {
    // TODO: Handle Formattable and time types?
    const {_links:resourcesModel, ...otherElementsModel} = formModel;
    const model = {
      ...otherElementsModel,
      _links: this._getFormattedResourcesModel(resourcesModel),
    }

    return model;
  }

  private _getFormattedResourcesModel(resourcesModel:IOPFormModel['_links'] = {}): IOPFormModel['_links']{
    return Object.keys(resourcesModel).reduce((result, resourceKey) => {
      const resource = resourcesModel[resourceKey];
      // ng-select needs a 'name' in order to show the label
      // We need to add it in case of the form payload (HalLinkSource)
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
    const { key, name:label, required } = field;
    const { templateOptions, ...fieldTypeConfig } = this._getFieldTypeConfig(field);
    const fieldOptions = this._getFieldOptions(field);
    const formlyFieldConfig = {
      ...fieldTypeConfig,
      key,
      className: `op-form--field ${fieldTypeConfig.className}`,
      templateOptions: {
        required,
        label,
        ...templateOptions,
        ...fieldOptions && {options: fieldOptions},
      },
    }

    return formlyFieldConfig;
  }

  private _getFieldTypeConfig(field:IFieldSchemaWithKey):FormlyFieldConfig {
    let inputType = this.inputsCatalogue.find(inputType => inputType.useForFields.includes(field.type))!;
    let inputConfig = inputType.config;
    let configCustomizations;

    if (field.type === 'integer' || field.type === 'select') {
      configCustomizations = { className: `${inputConfig.className} ${field.name}` };
    } else if (field.type === 'formattable') {
      configCustomizations = {
        templateOptions: {
          ...inputConfig.templateOptions,
          rtl: field.options?.rtl,
          name: field.name,
        },
      };
    }

    return {...inputConfig, ...configCustomizations};
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
        wrappers: ['op-form-dynamic-field-group-wrapper'],
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
}
