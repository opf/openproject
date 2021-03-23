import { HttpClient } from "@angular/common/http";
import { Injectable, OnDestroy } from "@angular/core";
import { FormArray, FormGroup } from "@angular/forms";
import { FormlyFieldConfig, FormlyForm } from "@ngx-formly/core";
import { Observable, of, ReplaySubject, Subscription } from "rxjs";
import { debounceTime, distinctUntilChanged, map, switchMap } from "rxjs/operators";
import {
  IDynamicForm,
  IFieldSchemaWithKey,
  IOPForm,
  IAttributeGroup,
  IFormSchema,
  IFormPayload,
  IFormModelChanges,
  IFieldTypeMap, IOPFormlyFieldConfig,
} from "../typings";
import { mergeFormModels } from "../utils/utils";
import { DynamicFormsHubService } from "./dynamic-forms-hub.service";

@Injectable()
export class DynamicFormService implements OnDestroy {
  form:FormlyForm;
  formId:string;
  projectId:string;
  typeHref:string;
  formModelChanges:IFormModelChanges;
  formSubcription:Subscription;
  fieldTypeSubcription:Subscription;

  private _form = new ReplaySubject<IDynamicForm>(1);
  readonly form$:Observable<IDynamicForm> = this._form.asObservable();

  constructor(
    private httpClient:HttpClient,
    private dynamicFormsHubService:DynamicFormsHubService,
  ) {}

  ngOnDestroy() {
    this.formSubcription?.unsubscribe();
    this.dynamicFormsHubService.unregisterForm(this);
  }

  registerForm(formlyForm:FormlyForm) {
    if (!formlyForm) { return; }

    this.form = formlyForm;
    this._observeFormModelChanges(formlyForm.form);
    this.dynamicFormsHubService.registerForm(this);    
  }

  private _observeFormModelChanges(form:FormGroup | FormArray) {
    this.formSubcription?.unsubscribe();

    this.formSubcription = form
      .valueChanges
      .pipe(
        debounceTime(300),
        distinctUntilChanged(),         
      )
      .subscribe(formModel => this.formModelChanges = this._getFormModelChanges(form));
  }

  private _getFormModelChanges(form: FormGroup | FormArray) {
    let dirtyValues:{[key: string]: unknown} = {};
    // TODO: type this
    let controls = form.controls as any;

    Object.keys(form.controls).forEach(key => {
      let currentControl = controls[key];

      if (currentControl.dirty) {
        if (currentControl.controls) {
          dirtyValues[key] = this._getFormModelChanges(currentControl);
        } else {
          dirtyValues[key] = currentControl.value;
        }
      }
    });

    return dirtyValues;
  }  

  // TODO: Implement passing the params and lockVersion
  getForm$(typeHref = this.typeHref, formId = this.formId, projectId = this.projectId, useBackUp = true): Observable<IDynamicForm>{     
    this.formId = formId;
    this.projectId = projectId;
    this.typeHref = typeHref;

    if (useBackUp) {
      const backUpChanges = this.dynamicFormsHubService.getBackUpFormChanges(this.formId);
      // TODO: Do final implementation (if formId omit type and project...)
      // Overwrite the type if it is present in unsaved changes
      const backUpTypeHref = backUpChanges?._links?.type?._links?.self.href || 
                              backUpChanges?._links?.type?.href;

      if (backUpTypeHref) {
        this.typeHref =  backUpTypeHref;
      }
    }

    // TODO: Replace with dynamic url
    let url = '/api/v3/projects/form';

    return this.httpClient
      .post<IOPForm>(
        url,
        {},
        {withCredentials: true,
        responseType: 'json'
      })
      .pipe(
        map((formConfig => {
          const formlyForm = this._getFormlyForm(formConfig);
          const formWithModelChanges = this._getFormWithModelChanges(formlyForm);

          this._form.next(formWithModelChanges);
        })),
        switchMap(() => this.form$)
      )
  }

  private _getFormWithModelChanges(form: IDynamicForm) {
    form = {
      ...form,
      model: this._getModelWithChanges(form.model, this.formModelChanges)
    };

    return form;
  }

  // TODO: Handle all possible data structures
  private _getModelWithChanges(formModel: IDynamicForm["model"], formChanges = {}) {
    // Overwrite backUpFormChanges with formChanges and then
    // overwrite formModel (backend payload) with the result
    const formChangesPlusBackUpFormChanges = mergeFormModels(this.dynamicFormsHubService.getBackUpFormChanges(this.formId), formChanges);

    return mergeFormModels(formModel, formChangesPlusBackUpFormChanges);
    
    /*return Object.keys(formChanges).reduce(
      (formModel, fieldChangeKey) => {
        const fieldChange = formChanges[fieldChangeKey];

        if (fieldChangeKey === "_links") {
          formModel._links = {
            ...formModel._links,
            ...fieldChange
          };
        } else {
          formModel = {
            ...formModel,
            [fieldChangeKey]: fieldChange
          };
        }

        return formModel;
      },
      { ...formModel }
    );*/
  }

  private _getFormlyForm(formConfig:IOPForm):IDynamicForm {
    // TODO: Remove this filtering
    // const formSchema = formConfig._embedded?.schema;
    const {name, id, parent, status, active, customField12, statusExplanation, description, _attributeGroups, _links, lockVersion, _dependencies, _type, ...formSchemaRest} = formConfig._embedded?.schema;
    const formSchema = {name, id, parent, status, active, customField12, statusExplanation, description, _attributeGroups, _links, lockVersion, _dependencies, _type};
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

  private _getFieldsSchemas(formSchema:IFormSchema, formModel:IFormPayload):IFieldSchemaWithKey[] {
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
    const {type, key, name:label, required, hasDefault, writable} = field;
    const {templateOptions, ...fieldTypeConfig} = this._getFieldTypeConfig(field);
    const fieldOptions = this._getFieldOptions(field);
    const formlyFieldConfig = {
      ...fieldTypeConfig,
      key,
      className: `op-form--field ${fieldTypeConfig.className}`,
      //wrappers: ["op-form-field-wrapper", "form-field"],
      templateOptions: {
        required,
        label,
        disabled: !writable,
        ...templateOptions, // ...writable && templateOptions, // Only when writable?
        ...fieldOptions && {options: fieldOptions},        
      },
      // Reset the form when the work package type changes
      // and so the form schema changes too
      ...field.key === '_links.type' && {
        hooks: {
          onInit: (field:FormlyFieldConfig) => {
            this.fieldTypeSubcription?.unsubscribe();

            this.fieldTypeSubcription = field.formControl!
              .valueChanges
              .pipe(switchMap((type) => {
                // The model differ between the payload ({title, href}) and the
                // API responses (Resource with _links...)
                const newTypeHref = type?._links?.self?.href || type?.href;

                return newTypeHref !== this.typeHref ?
                  this.getForm$(newTypeHref, undefined, undefined, false) :
                  of(null);

                /*if (newTypeHref !== this.typeHref) {
                  this.typeHref = newTypeHref;

                  return this.getForm$(newTypeHref);
                } else {
                  return of(null);
                }*/
              }))
              .subscribe();
          }
        }
      },
      // TODO: Remove this mocks
      /*...field.key === 'description' && {
        asyncValidators: {
          nameWithA: {
            expression: (control: FormControl) => of(control.value?.includes('a')),
            message: 'The name must contain an a.',
          }
        }
      },*/
      /*...field.key.includes('_links') && {
        // Process the model in anyway examples
        // parsers: [(value) => value.hi = 'hi'],
        expressionProperties: {
          [`model.${key}`]: (model, formState) => {            
            const resourceKey = key.split('.').pop();
            return model._links[resourceKey];
          },
        }
      },*/      
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

 /* // TODO: Check why is this
  if (!allowedValues && field.type !== 'User') {
  return;
}

if (field._embedded?.allowedValues) {
  return of(field._embedded?.allowedValues);
} else if (field._links?.allowedValues) {
  this.httpClient
    .get(field._links?.allowedValues.href)
    .pipe(
      map((response: api.v3.Result) => response._embedded.elements)
    );
} else {
  return of([]);
}*/

  private _getFieldsModel(fieldSchemas:IFieldSchemaWithKey[], formModel:IFormPayload = {}) {
    const {_links:resourcesModel, ...otherElementsModel} = formModel;
    const model = {
      ...otherElementsModel,
      _links: this._getFormattedResourcesModel(resourcesModel),
    }

    // TODO: Handle Formattable and time types
    // TODO: Type this
    /*
    model.description = model.description.raw;
    model.remainingTime = Number(moment.duration(model.remainingTime).asHours().toFixed(2));
    model.estimatedTime = Number(moment.duration(model.estimatedTime).asHours().toFixed(2));
    model.spentTime = Number(moment.duration(model.spentTime).asHours().toFixed(2));
     */
    
    return model;
  }

  private _getFormattedResourcesModel(resourcesModel:IFormPayload['_links'] = {}){
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
}