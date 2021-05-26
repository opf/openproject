import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from "@angular/common/http/testing";
import { HttpClient } from "@angular/common/http";
import { DynamicFieldsService } from "core-app/modules/common/dynamic-forms/services/dynamic-fields/dynamic-fields.service";
import { isObservable } from "rxjs";
import { IOPFormlyFieldSettings } from "core-app/modules/common/dynamic-forms/typings";

describe('DynamicFieldsService', () => {
  let httpClient: HttpClient;
  let httpTestingController: HttpTestingController;
  let service:DynamicFieldsService;
  const formSchema = {
    "name": {
      "type": "String",
      "name": "Name",
      "required": true,
      "hasDefault": false,
      "writable": true,
      "minLength": 1,
      "maxLength": 255,
      "options": {}
    },
    "parent": {
      "type": "Project",
      "name": "Subproject of",
      "required": false,
      "hasDefault": false,
      "location": "_links",
      "writable": true,
      "_links": {
        "allowedValues": {
          "href": "/api/v3/projects/available_parent_projects?of=25"
        }
      }
    },
    "id": {
      "type": "Integer",
      "name": "ID",
      "required": true,
      "hasDefault": false,
      "writable": false,
      "options": {}
    },
    _dependencies: [],
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        HttpClientTestingModule,
      ],
      providers: [
        DynamicFieldsService,
      ]
    });
    httpClient = TestBed.inject(HttpClient);
    httpTestingController = TestBed.inject(HttpTestingController);
    service = TestBed.inject(DynamicFieldsService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should generate a proper dynamic form schema', () => {
    const formPayload = {
      "name": "Project 1",
      "_links": {
        "parent": {
          "href": "/api/v3/projects/26",
          "title": "Parent project"
        }
      }
    };

    // @ts-ignore
    const fieldsSchemas = service.getFieldsSchemasWithKey(formSchema, formPayload);

    expect(fieldsSchemas.length).toBe(2, 'should return only writable field schemas');
    expect(fieldsSchemas[0].key).toBe('name', 'should place the correct key on primitives');
    expect(fieldsSchemas[1].key).toBe('_links.parent', 'should place the correct key on resources');
  });

  it('should format the form model (add the name property to resources (_links: single and multiple))', () => {
    const formPayload = {
      "title": "Project 1",
      "_links": {
        "parent": {
          "href": "/api/v3/projects/26",
          "title": "Parent project"
        },
        "children": [
          {
            "href": "/api/v3/projects/27",
            "title": "Child project 1"
          },
          {
            "href": "/api/v3/projects/28",
            "title": "Child project 2"
          }
        ]
      },
    };

    // @ts-ignore
    const formModel = service.getModel(formPayload);
    const titleName = formModel.title;
    const parentProjectName = !Array.isArray(formModel._links!.parent) && formModel._links!.parent!.name;
    const childrenProjectsNames = Array.isArray(formModel._links!.children) && formModel._links!.children!.map((childProject: IOPFieldModel) => childProject.name);

    expect(titleName).toBe('Project 1', 'should add the payload value on primitives');
    expect(parentProjectName).toEqual('Parent project', 'should add a name property on resources');
    expect(childrenProjectsNames).toEqual(['Child project 1', 'Child project 2'], 'should add a name property on resources with multiple values');
  });

  it('should generate a proper dynamic form config', () => {
    const formPayload = {
      "name": "Project 1",
      "_links": {
        "parent": {
          "href": "/api/v3/projects/26",
          "title": "Parent project"
        },
      }
    };
    const {parent, name} = formSchema;
    const formSchemaWithGroups = {
      parent,
      name,
      _attributeGroups: [
        {
          "_type": "WorkPackageFormAttributeGroup",
          "name": "People",
          "attributes": [
            "name",
          ]
        },
      ]
    };
    // @ts-ignore
    const formlyConfig = service.getConfig(formSchemaWithGroups, formPayload);
    const formlyFields = formlyConfig.reduce((result, formlyField) => {
      return formlyField.fieldGroup ? [...result, ...formlyField.fieldGroup] : [...result, formlyField];
    }, [] as IOPFormlyFieldSettings[]);
    const formGroup = formlyConfig[1];

    expect(formlyFields[1].templateOptions!.label).toBe('Name', 'should set the correct label');
    expect(isObservable(formlyFields[0].templateOptions!.options)).toBeTruthy('should add options as observables');
    expect(formlyFields[0].className).toContain('Subproject of', 'should add the specific input type properties');
    expect(formlyFields[0].templateOptions!.locale).toBeTruthy('should add the specific input templateOptions');

    expect(formGroup).toBeTruthy();
    expect(formGroup.templateOptions!.label).toEqual('People', 'should add the correct label to the field group wrapper');
    expect(formGroup.fieldGroup![0].key).toEqual('name', 'should add the correct key to the field group wrapper');
  });

  it('should group fields from @Input fieldGroups (IDynamicFieldGroupConfig)', () => {
    const formPayload = {};
    const {parent, name} = formSchema;
    const formSchemaWithGroups = {
      parent,
      name,
      "id": {
        "type": "Integer",
        "name": "ID",
        "required": true,
        "hasDefault": false,
        "writable": true,
        "options": {}
      },
      _attributeGroups: [
        {
          "_type": "WorkPackageFormAttributeGroup",
          "name": "People",
          "attributes": [
            "name",
          ]
        },
      ]
    };
    const fieldGroups = [
      {
        name: 'Advanced settings',
        fieldsFilter: (field:IOPFormlyFieldSettings) => ['name', 'parent'].includes(field.templateOptions?.property!),
        settings: {
          templateOptions: {
            collapsibleFieldGroupsCollapsed: false
          }
        }
      }
    ];
    const formConfig = service.getConfig(formSchemaWithGroups, formPayload);
    const formConfigWithFieldGroups = service.getFormlyFormWithFieldGroups(fieldGroups, formConfig);
    const fieldGroup = formConfigWithFieldGroups[1];

    expect(formConfigWithFieldGroups?.length).toBe(2, 'should create the correct number of fields (1 field + 1 field group)');
    expect(fieldGroup?.wrappers![0]).toBe('op-dynamic-field-group-wrapper', 'should set the correct group label');
    expect(fieldGroup?.templateOptions?.label).toBe(fieldGroups[0].name, 'should set the correct group label (overwriting previous grouping)');
    expect(fieldGroup?.templateOptions?.isFieldGroup).toBe(true, 'should set isFieldGroup to true');
    expect(fieldGroup?.templateOptions?.collapsibleFieldGroups).toBe(true, 'should set collapsibleFieldGroups to true');
    expect(fieldGroup?.templateOptions?.collapsibleFieldGroupsCollapsed).toBe(false, 'should overwrite the default group options with the group settings');
    expect(fieldGroup?.fieldGroup?.length).toBe(2, 'should contain the correct number of fields');
  });
});
