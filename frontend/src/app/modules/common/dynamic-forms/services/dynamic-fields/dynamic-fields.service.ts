import { Injectable } from '@angular/core';
import {
  IOPDynamicInputTypeSettings,
  IOPFormlyFieldSettings,
} from "../../typings";
import { FormlyFieldConfig } from "@ngx-formly/core";
import { of } from "rxjs";
import { map } from "rxjs/operators";
import { HttpClient } from "@angular/common/http";


@Injectable({
  providedIn: 'root'
})
export class DynamicFieldsService {
  readonly inputsCatalogue:IOPDynamicInputTypeSettings[] = [
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
        type: 'textInput',
        className: 'inline-edit--field',
        templateOptions: {
          type: 'password',
        },
      },
      useForFields: ['Password']
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
          noWrapLabel: true,
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
          'templateOptions.clearable': (model:any, formState:any, field:FormlyFieldConfig) => !field.templateOptions?.required,
        },
      },
      useForFields: [
        'Priority', 'Status', 'Type', 'User', 'Version', 'TimeEntriesActivity',
        'Category', 'CustomOption', 'Project', 'ProjectStatus'
      ]
    },
  ]

  constructor(
    private _httpClient:HttpClient,
  ) { }

  getConfig(formSchema:IOPFormSchema, formPayload:IOPFormModel):IOPFormlyFieldSettings[] {
    const formFieldGroups = formSchema._attributeGroups;
    const fieldSchemas = this._getFieldsSchemasWithKey(formSchema);
    const formlyFields = fieldSchemas.map(fieldSchema => this._getFormlyFieldConfig(fieldSchema));
    const formlyFormWithFieldGroups = this._getFormlyFormWithFieldGroups(formFieldGroups, formlyFields);

    return formlyFormWithFieldGroups;
  }

  getModel(formSchema:IOPFormSchema, formPayload:IOPFormModel):IOPFormModel {
    const fieldSchemas = this._getFieldsSchemasWithKey(formSchema);
    const fieldsModel = this._getFieldsModel(fieldSchemas, formPayload);

    return fieldsModel;
  }

  private _getFieldsSchemasWithKey(formSchema:IOPFormSchema):IOPFieldSchemaWithKey[] {
    return Object.keys(formSchema)
      .map(fieldSchemaKey => {
        const fieldSchema = {
          ...formSchema[fieldSchemaKey],
          key: this._isResourceSchema(formSchema[fieldSchemaKey]) ?
            `_links.${fieldSchemaKey}` :
            fieldSchemaKey
        };

        return fieldSchema;
      })
      .filter(fieldSchema => this._isFieldSchema(fieldSchema) && fieldSchema.writable);
  }

  private _isResourceSchema(fieldSchemaKey:string, formModel:IOPFormModel):boolean {
    return !!(formModel?._links && fieldSchemaKey in formModel._links);
  }

  private _isFieldSchema(schemaValue:IOPFieldSchemaWithKey | any):boolean {
    return schemaValue?.type;
  }

  private _getFieldsModel(fieldSchemas:IFieldSchemaWithKey[], formModel:IOPFormModel = {}):IOPFormModel {
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

  private _getFormlyFieldConfig(field:IOPFieldSchemaWithKey):IOPFormlyFieldSettings {
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
    };

    return formlyFieldConfig;
  }

  private _getFieldTypeConfig(field:IOPFieldSchemaWithKey):IOPFormlyFieldSettings {
    const fieldType = field.type.replace('[]', '') as OPFieldType;
    let inputType = this.inputsCatalogue.find(inputType => inputType.useForFields.includes(fieldType))!;
    let inputConfig = inputType.config;
    let configCustomizations;

    if (inputConfig.type === 'integerInput' || inputConfig.type === 'selectInput') {
      configCustomizations = {
        className: `${inputConfig.className} ${field.name}`,
        ...field.type.startsWith('[]') && {
          templateOptions: {
            ...inputConfig.templateOptions,
            multiple: true
          }
        },
      };
    } else if (inputConfig.type === 'formattableInput') {
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

  private _getFieldOptions(field:IOPFieldSchemaWithKey) {
    const allowedValues = field._embedded?.allowedValues || field._links?.allowedValues;

    if (!allowedValues) {
      return;
    }

    if (Array.isArray(allowedValues)) {
      const options = allowedValues[0]?._links?.self?.title ?
        this._formatAllowedValues(allowedValues) :
        allowedValues;

      return of(options);
    } else if (allowedValues!.href) {
      return this._httpClient
        .get(allowedValues!.href!)
        .pipe(
          map((response: api.v3.Result) => response._embedded.elements),
          map(options => options.map((option:IFieldSchema['options']) => ({...option, title: option._links?.self?.title})))
        );
    }

    return;
  }

  // ng-select needs a 'name' in order to show the label
  // We need to add it in case of the form payload (HalLinkSource)
  private _formatAllowedValues(options: IOPAllowedValue[]) {
    return options.map((option:IOPFieldSchema['options']) => ({...option, name: option._links?.self?.title}));
  }

  private _getFormlyFormWithFieldGroups(fieldGroups:IAttributeGroup[] = [], formFields:IOPFormlyFieldConfig[] = []):IOPFormlyFieldConfig[] {
    const fieldGroupKeys = fieldGroups.reduce((groupKeys, fieldGroup) => [...groupKeys, ...fieldGroup.attributes], []);
    const fomFieldsWithoutGroup = formFields.filter(formField => {
      const formFieldKey = formField.key?.split('.')?.pop();

      return formFieldKey ?
        !fieldGroupKeys.includes(formFieldKey) :
        true;
    });
    const formFieldGroups = fieldGroups.reduce((formWithFieldGroups: IOPFormlyFieldSettings[], fieldGroup) => {
      const newFormFieldGroup = {
        wrappers: ['op-dynamic-field-group-wrapper'],
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
