import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { HttpClient } from '@angular/common/http';
import { UntypedFormBuilder } from '@angular/forms';
import { FormsService } from './forms.service';

describe('FormsService', () => {
  let service:FormsService;
  let httpClient:HttpClient;
  let httpTestingController:HttpTestingController;
  const testFormUrl = 'http://op.com/form';
  const formModel = {
    name: 'Project 1',
    _links: {
      parent: {
        href: '/api/v3/projects/26',
        title: 'Parent project',
        name: 'Parent project',
      },
      users: [
        {
          href: '/api/v3/users/26',
          title: 'User 1',
          name: 'User 1',
        },
      ],
    },
  };
  const formBuilder = new UntypedFormBuilder();

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        HttpClientTestingModule,
      ],
    });
    httpClient = TestBed.inject(HttpClient);
    httpTestingController = TestBed.inject(HttpTestingController);
    service = TestBed.inject(FormsService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should submit the dynamic form value', () => {
    const form = formBuilder.group(formModel);
    const resourceId = '123';

    service
      .submit$(form, testFormUrl)
      .subscribe();

    const postReq = httpTestingController.expectOne(testFormUrl);

    expect(postReq.request.method).toEqual('POST', 'should create a new resource when no id is provided');
    expect(postReq.request.body.name).toEqual('Project 1', 'should upload the primitive values as they are');
    expect(postReq.request.body._links.parent).toEqual({ href: '/api/v3/projects/26' }, 'should format the resource values to only contain the href');

    postReq.flush('ok response');
    httpTestingController.verify();

    service
      .submit$(form, testFormUrl, resourceId)
      .subscribe();

    const patchReq = httpTestingController.expectOne(`${testFormUrl}/${resourceId}`);

    expect(patchReq.request.method).toEqual('PATCH', 'should update the resource when an id is provided');

    patchReq.flush('ok response');
    httpTestingController.verify();
  });

  it('should format the model to fit the backend expectation', () => {
    // @ts-ignore
    const formattedModel = service.formatModelToSubmit(formModel);
    const expectedResult = {
      name: 'Project 1',
      _links: {
        parent: {
          href: '/api/v3/projects/26',
        },
        users: [
          {
            href: '/api/v3/users/26',
          },
        ],
      },
    };

    expect(formattedModel).toEqual(expectedResult);
  });

  it('should set the backend errors in the FormGroup', () => {
    const form = formBuilder.group({
      ...formModel,
      _links: formBuilder.group(formModel._links),
    });
    const backEndErrorResponse = {
      error: {
        _type: 'Error',
        errorIdentifier: 'urn:openproject-org:api:v3:errors:MultipleErrors',
        message: 'Multiple field constraints have been violated.',
        _embedded: {
          errors: [
            {
              _type: 'Error',
              errorIdentifier: 'urn:openproject-org:api:v3:errors:PropertyConstraintViolation',
              message: "Name can't be blank.",
              _embedded: {
                details: {
                  attribute: 'name',
                },
              },
            },
            {
              _type: 'Error',
              errorIdentifier: 'urn:openproject-org:api:v3:errors:PropertyConstraintViolation',
              message: "Identifier can't be blank.",
              _embedded: {
                details: {
                  attribute: 'parent',
                },
              },
            },
          ],
        },
      },
      status: 422,
    };

    // @ts-ignore
    service.handleBackendFormValidationErrors(backEndErrorResponse, form);

    expect(form.get('name')!.invalid).toBe(true);
    expect(form.get('_links')!.get('parent')!.invalid).toBe(true);
    expect(form.get('_links')!.get('users')!.valid).toBe(true);
  });
});
