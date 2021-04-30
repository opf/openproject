import { Injectable } from '@angular/core';
import {
  IOPDynamicInputTypeSettings,
  IOPFormlyFieldSettings,
} from "../../typings";
import { FormlyFieldConfig } from "@ngx-formly/core";
import { of } from "rxjs";
import { map } from "rxjs/operators";
import { HttpClient } from "@angular/common/http";


@Injectable()
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
  ];

  constructor(
    private _httpClient:HttpClient,
  ) { }

  getConfig(formSchema:IOPFormSchema, formPayload:IOPFormModel):IOPFormlyFieldSettings[] {
    const formFieldGroups = formSchema._attributeGroups;
    const fieldSchemas = this._getFieldsSchemasWithKey(formSchema);
    const formlyFields = fieldSchemas
      .map(fieldSchema => this._getFormlyFieldConfig(fieldSchema))
      .filter(f => f !== null) as IOPFormlyFieldSettings[];
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

  private _isResourceSchema(fieldSchema: IOPFieldSchema):boolean {
    return fieldSchema.location === '_links';
  }

  private _isFieldSchema(schemaValue:IOPFieldSchemaWithKey | any):boolean {
    return schemaValue?.type;
  }

  private _getFieldsModel(fieldSchemas:IOPFieldSchemaWithKey[], formModel:IOPFormModel = {}):IOPFormModel {
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

  private _getFormlyFieldConfig(field:IOPFieldSchemaWithKey):IOPFormlyFieldSettings|null {
    const { key, name:label, required } = field;
    const fieldTypeConfigSearch = this._getFieldTypeConfig(field);
    if (!fieldTypeConfigSearch) {
      return null;
    }
    const { templateOptions, ...fieldTypeConfig } = fieldTypeConfigSearch;
    const fieldOptions = this._getFieldOptions(field);
    const formlyFieldConfig = {
      ...fieldTypeConfig,
      key,
      className: `op-form--field ${fieldTypeConfig.className}`,
      wrappers: [`op-dynamic-field-wrapper`],
      templateOptions: {
        property: this.getFieldProperty(key),
        required,
        label,
        ...templateOptions,
        ...fieldOptions && {options: fieldOptions},
      },
    };

    return formlyFieldConfig;
  }

  private _getFieldTypeConfig(field:IOPFieldSchemaWithKey):IOPFormlyFieldSettings|null {
    const fieldType = field.type.replace('[]', '') as OPFieldType;
    let inputType = this.inputsCatalogue.find(inputType => inputType.useForFields.includes(fieldType))!;
    if (!inputType) {
      console.warn(
        `Could not find a input definition for a field with the folowing type: ${fieldType}.
          The full field configuration is ${field}`
      ); 
      return null;
    }
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
          map(options => this._formatAllowedValues(options)),
        );
    }

    return;
  }

  // ng-select needs a 'name' in order to show the label
  // We need to add it in case of the form payload (HalLinkSource)
  private _formatAllowedValues(options: IOPAllowedValue[]) {
    return options.map((option:IOPFieldSchema['options']) => ({...option, name: option._links?.self?.title}));
  }

  // Map a field key that may be a _links.property to the property name
  private getFieldProperty(key:string) {
    return key.split('.').pop();
  }

  private _getFormlyFormWithFieldGroups(fieldGroups:IOPAttributeGroup[] = [], formFields:IOPFormlyFieldSettings[] = []):IOPFormlyFieldSettings[] {
    const fieldGroupKeys = fieldGroups.reduce((groupKeys, fieldGroup) => [...groupKeys, ...fieldGroup.attributes], []);
    const fomFieldsWithoutGroup = formFields.filter(formField => {
      const formFieldKey = formField.key && this.getFieldProperty(formField.key);

      return formFieldKey ?
        !fieldGroupKeys.includes(formFieldKey) :
        true;
    });
    const formFieldGroups = fieldGroups.reduce((formWithFieldGroups: IOPFormlyFieldSettings[], fieldGroup) => {
      const newFormFieldGroup = {
        wrappers: ['op-dynamic-field-group-wrapper'],
        fieldGroupClassName: 'op-form-group',
        templateOptions: {
          label: fieldGroup.name,
          isFieldGroup: true,
          collapsibleFieldGroups: false,
          collapsibleFieldGroupsCollapsed: true,
        },
        fieldGroup: formFields.filter(formField => {
          const formFieldKey = formField.key && this.getFieldProperty(formField.key);

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
