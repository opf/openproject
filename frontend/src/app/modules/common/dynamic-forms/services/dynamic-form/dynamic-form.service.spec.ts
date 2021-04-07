import { TestBed } from '@angular/core/testing';
import { DynamicFormService } from "core-app/modules/common/dynamic-forms/services/dynamic-form/dynamic-form.service";
import { HttpClientTestingModule, HttpTestingController } from "@angular/common/http/testing";
import { HttpClient } from "@angular/common/http";
import { IOPForm } from "core-app/modules/common/dynamic-forms/typings";

describe('DynamicFormService', () => {
  let httpClient: HttpClient;
  let httpTestingController: HttpTestingController;
  let service:DynamicFormService;
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
        DynamicFormService,
      ]
    });
    httpClient = TestBed.inject(HttpClient);
    httpTestingController = TestBed.inject(HttpTestingController);
    service = TestBed.inject(DynamicFormService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});