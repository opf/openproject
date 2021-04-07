import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from "@angular/common/http/testing";
import { HttpClient } from "@angular/common/http";
import { IOPFieldModel, IOPForm } from "core-app/modules/common/dynamic-forms/typings";
import { DynamicFieldsService } from "core-app/modules/common/dynamic-forms/services/dynamic-fields/dynamic-fields.service";

fdescribe('DynamicFieldsService', () => {
  let httpClient: HttpClient;
  let httpTestingController: HttpTestingController;
  let service:DynamicFieldsService;
  const formSchema:IOPForm = {
    "_type": "Form",
    "_embedded": {
      "payload": {
        "identifier": "test11",
        "name": "asda",
        "active": true,
        "public": false,
        "description": {
          "format": "markdown",
          "raw": "asdadsad",
          "html": "<p class=\"op-uc-p\">asdadsad</p>"
        },
        "status": null,
        "statusExplanation": {
          "format": "markdown",
          "raw": null,
          "html": ""
        },
        "customField12": null,
        "_links": {
          "parent": {
            "href": "/api/v3/projects/26",
            "title": "Parent project"
          }
        }
      },
      "schema": {
        "_type": "Schema",
        "_dependencies": [],
        "id": {
          "type": "Integer",
          "name": "ID",
          "required": true,
          "hasDefault": false,
          "writable": false,
          "options": {}
        },
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
        "identifier": {
          "type": "String",
          "name": "Identifier",
          "required": true,
          "hasDefault": false,
          "writable": true,
          "minLength": 1,
          "maxLength": 100,
          "options": {}
        },
        "description": {
          "type": "Formattable",
          "name": "Description",
          "required": false,
          "hasDefault": false,
          "writable": true,
          "options": {}
        },
        "public": {
          "type": "Boolean",
          "name": "Public",
          "required": true,
          "hasDefault": false,
          "writable": true,
          "options": {}
        },
        "active": {
          "type": "Boolean",
          "name": "Active",
          "required": true,
          "hasDefault": false,
          "writable": true,
          "options": {}
        },
        "status": {
          "type": "ProjectStatus",
          "name": "Status",
          "required": false,
          "hasDefault": false,
          "writable": true,
          "options": {}
        },
        "statusExplanation": {
          "type": "Formattable",
          "name": "Status description",
          "required": false,
          "hasDefault": false,
          "writable": true,
          "options": {}
        },
        "parent": {
          "type": "Project",
          "name": "Subproject of",
          "required": false,
          "hasDefault": false,
          "writable": true,
          "_links": {
            "allowedValues": {
              "href": "/api/v3/projects/available_parent_projects?of=25"
            }
          }
        },
        "createdAt": {
          "type": "DateTime",
          "name": "Created on",
          "required": true,
          "hasDefault": false,
          "writable": false,
          "options": {}
        },
        "updatedAt": {
          "type": "DateTime",
          "name": "Updated on",
          "required": true,
          "hasDefault": false,
          "writable": false,
          "options": {}
        },
        "customField12": {
          "type": "Date",
          "name": "Date",
          "required": false,
          "hasDefault": false,
          "writable": true,
          "options": {
            "rtl": null
          }
        },
        "_links": {}
      },
      "validationErrors": {}
    },
    "_links": {
      "self": {
        "href": "/api/v3/projects/25/form",
        "method": "post"
      },
      "validate": {
        "href": "/api/v3/projects/25/form",
        "method": "post"
      },
      "commit": {
        "href": "/api/v3/projects/25",
        "method": "patch"
      }
    }
  }

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

  it('should generate a form schema that only contains field schemas with the correct key', () => {
    const formPayload = {
      "name": "Project 1",
      "_links": {
        "parent": {
          "href": "/api/v3/projects/26",
          "title": "Parent project"
        }
      }
    };
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
        "writable": true,
        "_links": {
          "allowedValues": {
            "href": "/api/v3/projects/available_parent_projects?of=25"
          }
        }
      },
      _dependencies: [],
    };

    // @ts-ignore
    const fieldsSchemas = service._getFieldsSchemasWithKey(formSchema, formPayload);

    expect(fieldsSchemas.length).toBe(2);
    expect(fieldsSchemas[0].key).toBe('name');
    expect(fieldsSchemas[1].key).toBe('_links.parent');
  });

  it('should format the form model', () => {
    const formPayload = {
      "name": "Project 1",
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
        "writable": true,
        "_links": {
          "allowedValues": {
            "href": "/api/v3/projects/available_parent_projects?of=25"
          }
        }
      },
      "children": {
        "type": "Project",
        "name": "Project's children",
        "required": false,
        "hasDefault": false,
        "writable": true,
        "_links": {
          "allowedValues": {
            "href": "/api/v3/projects/available_parent_projects?of=25"
          }
        }
      },
      _dependencies: [],
    };

    // @ts-ignore
    const fieldsSchemas = service._getFieldsSchemasWithKey(formSchema, formPayload);
    // @ts-ignore
    const fieldsModel = service._getFieldsModel(fieldsSchemas, formPayload);
    const parentProjectName = !Array.isArray(fieldsModel._links!.parent) && fieldsModel._links!.parent!.name;
    const childrenProjectsNames = Array.isArray(fieldsModel._links!.children) && fieldsModel._links!.children!.map((childProject: IOPFieldModel) => childProject.name);

    expect(fieldsModel.name).toBe('Project 1');
    expect(parentProjectName).toEqual('Parent project');
    expect(childrenProjectsNames).toEqual(['Child project 1', 'Child project 2']);
  });

  it('should aggregate the fields in fieldGroups if present', () => {
    const formPayload = {
      "name": "Project 1",
    };
    const formSchema = {
      "name": {
        "type": "String",
        "name": "Name",
        "required": true,
        "hasDefault": false,
        "writable": true,
        "minLength": 1,
        "maxLength": 255,
        "options": {},
        attributeGroup: "People"
      },
    };
    const formFieldGroups = [
      {
        "_type": "WorkPackageFormAttributeGroup",
        "name": "People",
        "attributes": [
          "name",
        ]
      },
    ];
    // @ts-ignore
    const fieldSchemas = service._getFieldsSchemasWithKey(formSchema, formPayload);
    // @ts-ignore
    const formlyFields = fieldSchemas.map(fieldSchema => service._getFormlyFieldConfig(fieldSchema));
    // @ts-ignore
    const formlyFormWithFieldGroups = service._getFormlyFormWithFieldGroups(formFieldGroups, formlyFields);
    const formGroup = formlyFormWithFieldGroups[0];

    expect(formGroup).toBeTruthy();
    expect(formGroup.wrappers![0]).toEqual('op-form-dynamic-field-group-wrapper');
    expect(formGroup.fieldGroupClassName).toEqual('op-form--field-group');
    expect(formGroup.templateOptions!.label).toEqual('People');
    expect(formGroup.fieldGroup![0].key).toEqual('name');
  })
});
