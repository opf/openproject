import { Injectable } from '@angular/core';
import { FormlyFieldConfig } from '@ngx-formly/core';
import { Observable, of } from 'rxjs';
import { map } from 'rxjs/operators';
import { HttpClient } from '@angular/common/http';
import { HalLink } from 'core-app/features/hal/hal-link/hal-link';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { FormsService } from 'core-app/core/forms/forms.service';
import { IDynamicFieldGroupConfig, IOPDynamicInputTypeSettings, IOPFormlyFieldSettings } from '../../typings';
import { addParamToHref } from 'core-app/shared/helpers/url-helpers';

@Injectable()
export class DynamicFieldsService {
  readonly selectDefaultValue = { name: '-', _links: { self: { href: null } } };

  readonly inputsCatalogue:IOPDynamicInputTypeSettings[] = [
    {
      config: {
        type: 'textInput',
        templateOptions: {
          type: 'text',
        },
      },
      useForFields: ['String'],
    },
    {
      config: {
        type: 'textInput',
        templateOptions: {
          type: 'password',
        },
      },
      useForFields: ['Password'],
    },
    {
      config: {
        type: 'textInput',
        templateOptions: {
          type: 'text',
        },
      },
      useForFields: ['Link'],
    },
    {
      config: {
        type: 'integerInput',
        templateOptions: {
          type: 'number',
          locale: this.I18n.locale,
        },
      },
      useForFields: ['Integer', 'Float'],
    },
    {
      config: {
        type: 'booleanInput',
        templateOptions: {
          type: 'checkbox',
        },
      },
      useForFields: ['Boolean'],
    },
    {
      config: {
        type: 'dateInput',
      },
      useForFields: ['Date', 'DateTime'],
    },
    {
      config: {
        type: 'userInput',
      },
      useForFields: ['User'],
    },
    {
      config: {
        type: 'formattableInput',
        className: '',
        templateOptions: {
          editorType: 'full',
          noWrapLabel: true,
        },
      },
      useForFields: ['Formattable'],
    },
    {
      config: {
        type: 'selectInput',
        defaultValue: this.selectDefaultValue,
        templateOptions: {
          locale: this.I18n.locale,
          bindLabel: 'name',
          searchable: true,
          virtualScroll: true,
          clearOnBackspace: false,
          clearSearchOnAdd: false,
          hideSelected: false,
          text: {
            add_new_action: this.I18n.t('js.label_create'),
          },
        },
        expressionProperties: {
          'templateOptions.clearable': (model:any, formState:any, field:FormlyFieldConfig) => !field.templateOptions?.required,
        },
      },
      useForFields: [
        'Priority', 'Status', 'Type', 'Version', 'TimeEntriesActivity',
        'Category', 'CustomOption',
      ],
    },
    {
      config: {
        type: 'projectInput',
        defaultValue: this.selectDefaultValue,
        templateOptions: {
          locale: this.I18n.locale,
          bindLabel: 'name',
        },
        expressionProperties: {
          'templateOptions.clearable': (model:any, formState:any, field:FormlyFieldConfig) => !field.templateOptions?.required,
        },
      },
      useForFields: [
        'Project',
      ],
    },
    {
      config: {
        type: 'selectProjectStatusInput',
        defaultValue: this.selectDefaultValue,
        templateOptions: {
          locale: this.I18n.locale,
          bindLabel: 'name',
          searchable: true,
        },
        expressionProperties: {
          'templateOptions.clearable': (model:any, formState:any, field:FormlyFieldConfig) => !field.templateOptions?.required,
        },
      },
      useForFields: [
        'ProjectStatus',
      ],
    },
  ];

  constructor(
    private httpClient:HttpClient,
    private I18n:I18nService,
    private formsService:FormsService,
  ) {
  }

  getConfig(formSchema:IOPFormSchema, formPayload:IOPFormModel):IOPFormlyFieldSettings[] {
    const formFieldGroups = formSchema._attributeGroups?.map((fieldGroup) => ({
      name: fieldGroup.name,
      fieldsFilter: (field:IOPFormlyFieldSettings) => fieldGroup.attributes?.includes(field.templateOptions?.property!),
    }));
    const fieldSchemas = this.getFieldsSchemasWithKey(formSchema);
    const formlyFields = fieldSchemas
      .map((fieldSchema) => this.getFormlyFieldConfig(fieldSchema, formPayload))
      .filter((f) => f !== null) as IOPFormlyFieldSettings[];
    const formlyFormWithFieldGroups = this.getFormlyFormWithFieldGroups(formFieldGroups, formlyFields);

    return formlyFormWithFieldGroups;
  }

  getModel(formPayload:IOPFormModel):IOPFormModel {
    return this.formsService.formatModelToEdit(formPayload);
  }

  getFormlyFormWithFieldGroups(fieldGroups:IDynamicFieldGroupConfig[] = [], formFields:IOPFormlyFieldSettings[] = []):IOPFormlyFieldSettings[] {
    // Remove previous grouping
    formFields = formFields.reduce((result:IOPFormlyFieldSettings[], formField) => (formField.fieldGroup ? [...result, ...formField.fieldGroup] : [...result, formField]), []);
    const formFieldsWithoutGroup = formFields.filter((formField) => fieldGroups.every((fieldGroup) => !fieldGroup.fieldsFilter || !fieldGroup.fieldsFilter(formField)));
    const formFieldGroups = this.getDynamicFormFieldGroups(fieldGroups, formFields);

    return [...formFieldsWithoutGroup, ...formFieldGroups];
  }

  private getFieldsSchemasWithKey(formSchema:IOPFormSchema):IOPFieldSchemaWithKey[] {
    return Object.keys(formSchema)
      .map((fieldSchemaKey) => {
        const fieldSchema = {
          ...formSchema[fieldSchemaKey],
          key: this.getAttributeKey(formSchema[fieldSchemaKey], fieldSchemaKey),
        };

        return fieldSchema;
      })
      .filter((fieldSchema) => this.isFieldSchema(fieldSchema) && fieldSchema.writable);
  }

  private getAttributeKey(fieldSchema:IOPFieldSchema, key:string):string {
    switch (fieldSchema.location) {
      case '_meta':
        return `${fieldSchema.location}.${key}`;
      default:
        return key;
    }
  }

  private isFieldSchema(schemaValue:IOPFieldSchemaWithKey|any):boolean {
    return !!schemaValue?.type;
  }

  private getFormlyFieldConfig(fieldSchema:IOPFieldSchemaWithKey, formPayload:IOPFormModel):IOPFormlyFieldSettings|null {
    const {
      key, name: label, required, hasDefault, minLength, maxLength,
    } = fieldSchema;
    const fieldTypeConfigSearch = this.getFieldTypeConfig(fieldSchema);
    if (!fieldTypeConfigSearch) {
      return null;
    }
    const { templateOptions, ...fieldTypeConfig } = fieldTypeConfigSearch;
    const property = this.getFieldProperty(key);
    const payloadValue = property && (formPayload[property] || formPayload._links && formPayload._links[property]);
    const fieldOptions = this.getFieldOptions(fieldSchema, payloadValue);
    const formlyFieldConfig = {
      ...fieldTypeConfig,
      key,
      wrappers: ['op-dynamic-field-wrapper'],
      className: `op-form--field ${fieldTypeConfig?.className || ''}`,
      templateOptions: {
        property,
        required,
        label,
        hasDefault,
        ...(payloadValue != null && { payloadValue }),
        ...(minLength && { minLength }),
        ...(maxLength && { maxLength }),
        ...templateOptions,
        ...(fieldOptions && { options: fieldOptions }),
        allowedValuesHref: fieldSchema?._links?.allowedValues?.href,
      },
    };

    return formlyFieldConfig;
  }

  private getFieldTypeConfig(field:IOPFieldSchemaWithKey):IOPFormlyFieldSettings|null {
    const fieldType = field.type.replace('[]', '') as OPFieldType;
    const inputType = this.inputsCatalogue.find((inputType) => inputType.useForFields.includes(fieldType))!;

    if (!inputType) {
      console.warn(
        `Could not find a input definition for a field with the following type: ${fieldType}. The full field configuration is`, field,
      );
      return null;
    }

    const inputConfig = inputType.config;
    let configCustomizations;

    if (
      inputConfig.type === 'integerInput'
      || inputConfig.type === 'selectInput'
      || inputConfig.type === 'selectProjectStatusInput'
      || inputConfig.type === 'userInput'
    ) {
      configCustomizations = {
        className: field.name,
        templateOptions: {
          ...inputConfig.templateOptions,
          ...(this.isMultiSelectField(field) && { multiple: true }),
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

    return { ...inputConfig, ...configCustomizations };
  }

  private getFieldOptions(field:IOPFieldSchemaWithKey, currentValue:HalLink|null):Observable<IOPAllowedValue[]>|undefined {
    const allowedValues = field._embedded?.allowedValues || field._links?.allowedValues;
    let options;

    if (!allowedValues) {
      return;
    }

    if (Array.isArray(allowedValues)) {
      const optionsValues = allowedValues[0]?._links?.self?.title
        ? this.formatAllowedValues(allowedValues)
        : allowedValues;

      options = of(optionsValues);
    } else if (allowedValues.href) {
      options = this.httpClient
        // The page size value of '-1' is a magic number that will result in the maximum allowed page size.
        .get(addParamToHref(allowedValues.href, { pageSize: '-1' }))
        .pipe(
          map((response:api.v3.Result) => response._embedded.elements),
          map((options) => this.formatAllowedValues(options)),
        );
    }

    return options?.pipe(
      map((options) => this.prependCurrentValue(options, currentValue)),
      map((options) => this.prependDefaultValue(options, field)),
    );
  }

  // ng-select needs a 'name' in order to show the label
  // We need to add it in case of the form payload (HalLinkSource)
  private formatAllowedValues(options:IOPAllowedValue[]):IOPAllowedValue[] {
    return options.map((option:IOPFieldSchema['options']) => ({ ...option, name: option._links?.self?.title }));
  }

  // Map a field key that may be a _links.property to the property name
  private getFieldProperty(key:string) {
    return key.split('.').pop();
  }

  private getDynamicFormFieldGroups(fieldGroups:IDynamicFieldGroupConfig[] = [], formFields:IOPFormlyFieldSettings[] = []) {
    return fieldGroups.reduce((formWithFieldGroups:IOPFormlyFieldSettings[], fieldGroup) => {
      let newFormFieldGroup = this.getDefaultFieldGroupSettings(fieldGroup, formFields);

      if (fieldGroup.settings) {
        newFormFieldGroup = {
          ...newFormFieldGroup,
          templateOptions: {
            ...newFormFieldGroup.templateOptions,
            ...(fieldGroup.settings.templateOptions && fieldGroup.settings.templateOptions),
          },
          expressionProperties: {
            ...newFormFieldGroup.expressionProperties,
            ...(fieldGroup.settings.expressionProperties && fieldGroup.settings.expressionProperties),
          },
        };
      }

      if (newFormFieldGroup?.fieldGroup?.length) {
        formWithFieldGroups = [...formWithFieldGroups, newFormFieldGroup];
      }

      return formWithFieldGroups;
    }, []);
  }

  private getDefaultFieldGroupSettings(fieldGroupConfig:IDynamicFieldGroupConfig, formFields:IOPFormlyFieldSettings[]):IOPFormlyFieldSettings {
    const defaultFieldGroupSettings = {
      wrappers: ['op-dynamic-field-group-wrapper'],
      fieldGroupClassName: 'op-form--fieldset',
      templateOptions: {
        label: fieldGroupConfig.name,
        isFieldGroup: true,
        collapsibleFieldGroups: true,
        collapsibleFieldGroupsCollapsed: true,
      },
      fieldGroup: this.getGroupFields(fieldGroupConfig, formFields),
      expressionProperties: {
        'templateOptions.collapsibleFieldGroupsCollapsed': this.collapsibleFieldGroupsCollapsedExpressionProperty,
      },
    };

    return defaultFieldGroupSettings;
  }

  private getGroupFields(fieldGroupConfig:IDynamicFieldGroupConfig, formFields:IOPFormlyFieldSettings[]) {
    return formFields.filter((formField) => {
      const formFieldKey = formField.key && this.getFieldProperty(formField.key);

      if (!formFieldKey) {
        return false;
      } if (fieldGroupConfig.fieldsFilter) {
        return fieldGroupConfig.fieldsFilter(formField);
      }
      return true;
    });
  }

  private collapsibleFieldGroupsCollapsedExpressionProperty(model:any, formState:any, field:FormlyFieldConfig) {
    // Uncollapse field groups when the form has errors and is submitted
    if (
      field.type !== 'formly-group'
      || !field.templateOptions?.collapsibleFieldGroups
      || !field.templateOptions?.collapsibleFieldGroupsCollapsed
    ) {
      return false;
    }

    return !(
      field.fieldGroup?.some((groupField:IOPFormlyFieldSettings) => groupField.formControl?.errors
        && !groupField.hide
        && field.options?.parentForm?.submitted));
  }

  // Invalid values, ones that are not in the list of allowedValues (Array or backend fetched) do occur, e.g.
  // if constraints change or in case a value is undisclosed as for a project's parent.
  private prependCurrentValue(options:IOPAllowedValue[], currentValue:HalLink|null):IOPAllowedValue[] {
    if (!currentValue?.href || options.some((option) => option?._links?.self?.href === currentValue.href)) {
      return options;
    }
    return [
      { name: currentValue.title, _links: { self: currentValue } },
      ...options,
    ];
  }

  // So select properties that are not required always get a default ('-'/'none') option.
  // This way, the user can more easily deselect a value.
  // Multi seleccts do not have the same behaviour since the x next to each option is quite clear.
  private prependDefaultValue(options:IOPAllowedValue[], field:IOPFieldSchemaWithKey):IOPAllowedValue[] {
    if (field.required || this.isMultiSelectField(field)) {
      return options;
    }
    return [this.selectDefaultValue, ...options];
  }

  private isMultiSelectField(field:IOPFieldSchemaWithKey) {
    return field?.type?.startsWith('[]');
  }
}
