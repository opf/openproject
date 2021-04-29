import { ComponentFixture, fakeAsync, flush, TestBed } from '@angular/core/testing';
import { DynamicFormComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-form/dynamic-form.component";
import { DynamicFormService } from "core-app/modules/common/dynamic-forms/services/dynamic-form/dynamic-form.service";
import { DynamicFieldsService } from "core-app/modules/common/dynamic-forms/services/dynamic-fields/dynamic-fields.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { By } from "@angular/platform-browser";
import { defer, of } from "rxjs";
import { FormControl, FormGroup, NG_VALUE_ACCESSOR, ReactiveFormsModule } from "@angular/forms";
import { CommonModule } from "@angular/common";
import { FormlyModule } from "@ngx-formly/core";
import { TextInputComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/text-input/text-input.component";
import { IntegerInputComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/integer-input/integer-input.component";
import { SelectInputComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/select-input/select-input.component";
import { BooleanInputComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/boolean-input/boolean-input.component";
import { DateInputComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/date-input/date-input.component";
import { FormattableTextareaInputComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/formattable-textarea-input/formattable-textarea-input.component";
import { DynamicFieldGroupWrapperComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-field-group-wrapper/dynamic-field-group-wrapper.component";
import { NgSelectModule } from "@ng-select/ng-select";
import { NgOptionHighlightModule } from "@ng-select/ng-option-highlight";
import { OpFormFieldComponent } from "core-app/modules/common/form-field/form-field.component";
import { Component, forwardRef, ViewChild } from "@angular/core";

@Component({
  template: `<op-dynamic-form [formControl]="control"></op-dynamic-form>`,
  providers: []
})
class DynamicFormsTestingComponent {
  control = new FormControl('');

  @ViewChild(DynamicFormComponent) dynamicFormControl:DynamicFormComponent;
}

describe('DynamicFormComponent', () => {
  let component: DynamicFormComponent;
  let fixture: ComponentFixture<DynamicFormComponent>;
  const formSchema:IOPFormSettings = {
    "_type": "Form",
    "_embedded": {
      "payload": {
        "name": "Project 1",
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
  };
  const dynamicFormSettings = {
    fields: [
      {
        "type": "textInput",
        "className": "op-form--field inline-edit--field",
        "key": "name",
        "templateOptions": {
          "required": true,
          "label": "Name",
          "type": "text",
          "placeholder": "",
          "disabled": false
        },
      },
      {
        "type": "integerInput",
        "className": "op-form--field inline-edit--field",
        "key": "quantity",
        "templateOptions": {
          "required": true,
          "label": "Quantity",
          "type": "number",
          "placeholder": "",
          "disabled": false
        },
      },
      {
        "type": "textInput",
        "className": "op-form--field inline-edit--field",
        "key": "identifier",
        "templateOptions": {
          "required": true,
          "label": "Identifier",
          "type": "text",
          "placeholder": "",
          "disabled": false
        },
      },
      {
        "type": "formattableInput",
        "className": "op-form--field textarea-wrapper",
        "key": "description",
        "templateOptions": {
          "required": false,
          "label": "Description",
          "editorType": "full",
          "inlineLabel": true,
          "placeholder": "",
          "disabled": false
        },
      },
      {
        "type": "booleanInput",
        "className": "op-form--field inline-edit--field inline-edit--boolean-field",
        "key": "public",
        "templateOptions": {
          "required": true,
          "label": "Public",
          "type": "checkbox",
          "placeholder": "",
          "disabled": false
        },
      },
      {
        "type": "booleanInput",
        "className": "op-form--field inline-edit--field inline-edit--boolean-field",
        "key": "active",
        "templateOptions": {
          "required": true,
          "label": "Active",
          "type": "checkbox",
          "placeholder": "",
          "disabled": false
        },
      },
      {
        "type": "selectInput",
        "className": "op-form--field inline-edit--field Status",
        "expressionProperties": {},
        "key": "status",
        "templateOptions": {
          "required": false,
          "label": "Status",
          "type": "number",
          "locale": "en",
          "bindLabel": "title",
          "searchable": false,
          "virtualScroll": true,
          "typeahead": false,
          "clearOnBackspace": false,
          "clearSearchOnAdd": false,
          "hideSelected": false,
          "text": {
            "add_new_action": "Create"
          },
          "placeholder": "",
          "disabled": false,
          "clearable": true,
          "multiple": false
        },
      },
      {
        "type": "formattableInput",
        "className": "op-form--field textarea-wrapper",
        "key": "statusExplanation",
        "templateOptions": {
          "required": false,
          "label": "Status description",
          "editorType": "full",
          "inlineLabel": true,
          "placeholder": "",
          "disabled": false
        },
      },
      {
        "type": "selectInput",
        "className": "op-form--field inline-edit--field Subproject of",
        "expressionProperties": {},
        "key": "_links.parent",
        "templateOptions": {
          "required": false,
          "label": "Subproject of",
          "type": "number",
          "locale": "en",
          "bindLabel": "title",
          "searchable": false,
          "virtualScroll": true,
          "typeahead": false,
          "clearOnBackspace": false,
          "clearSearchOnAdd": false,
          "hideSelected": false,
          "text": {
            "add_new_action": "Create"
          },
          "options": of([])
        },
      },
      {
        "type": "dateInput",
        "className": "op-form--field inline-edit--field",
        "key": "customField12",
        "templateOptions": {
          "required": false,
          "label": "Date",
          "placeholder": "",
          "disabled": false
        },
      }
    ],
    model: {
      "identifier": "test11",
      "name": "qwe",
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
          "href": "/api/v3/projects/23",
          "title": "qweqwe",
          "name": "qweqwe"
        }
      }
    },
    form: new FormGroup({}),
  }
  const I18nServiceStub = {
    t: function(key:string) {
      return 'test translation';
    }
  }
  const apiV3Base = 'http://www.openproject.com/api/v3/';
  const IPathHelperServiceStub = { api:{ v3: { apiV3Base }}};
  let notificationsService:jasmine.SpyObj<NotificationsService>;
  let dynamicFormService:jasmine.SpyObj<DynamicFormService>;

  beforeEach(async () => {
    const notificationsServiceSpy = jasmine.createSpyObj('NotificationsService', ['addError', 'addSuccess']);
    const dynamicFormServiceSpy = jasmine.createSpyObj('DynamicFormService', ['getSettings', 'getSettingsFromBackend$', 'registerForm', 'submit$']);

    await TestBed
      .configureTestingModule({
        imports: [
          CommonModule,
          ReactiveFormsModule,
          FormlyModule.forRoot({
            types: [
              { name: 'textInput', component: TextInputComponent },
              { name: 'integerInput', component: IntegerInputComponent },
              { name: 'selectInput', component: SelectInputComponent },
              { name: 'booleanInput', component: BooleanInputComponent },
              { name: 'dateInput', component: DateInputComponent },
              { name: 'formattableInput', component: FormattableTextareaInputComponent },
            ],
            wrappers: [
              {
                name: "op-dynamic-field-group-wrapper",
                component: DynamicFieldGroupWrapperComponent,
              },
            ]
          }),
          NgSelectModule,
          NgOptionHighlightModule,
        ],
        declarations: [
          DynamicFormComponent,
          OpFormFieldComponent,
          TextInputComponent,
          IntegerInputComponent,
          SelectInputComponent,
          BooleanInputComponent,
          DynamicFormsTestingComponent,
          // Skip adding DateInputComponent and FormattableTextareaInputComponent
          // to keep it simple (inheritance test issues).
        ],
        providers: [
          DynamicFieldsService,
          { provide: I18nService, useValue: I18nServiceStub },
          { provide: PathHelperService, useValue: IPathHelperServiceStub },
          { provide: NotificationsService, useValue: notificationsServiceSpy },
        ]
      })
      // Set component providers
      .overrideComponent(
        DynamicFormComponent,
        {
          set: {
            providers: [
              {
                provide: DynamicFormService,
                useValue: dynamicFormServiceSpy
              },
              {
                provide: NG_VALUE_ACCESSOR,
                multi: true,
                useExisting: forwardRef(() => DynamicFormComponent),
              }
            ]
          }
        }
      )
      .compileComponents();

    fixture = TestBed.createComponent(DynamicFormComponent);
    component = fixture.componentInstance;
    notificationsService = fixture.debugElement.injector.get(NotificationsService) as jasmine.SpyObj<NotificationsService>;
    dynamicFormService = fixture.debugElement.injector.get(DynamicFormService) as jasmine.SpyObj<DynamicFormService>;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should get the form schema from the backend when no @Input settings', fakeAsync(() => {
    // @ts-ignore
    dynamicFormService.getSettingsFromBackend$.and.returnValue(defer(() => Promise.resolve(dynamicFormSettings)));

    component.ngOnChanges();

    expect(dynamicFormService.getSettingsFromBackend$).toHaveBeenCalled();

    flush();

    fixture.detectChanges();

    expect(fixture.debugElement.query(By.css('[data-qa="op-form--container"]'))).toBeTruthy()
    expect(fixture.debugElement.queryAll(By.css('formly-form')).length).toEqual(1);
    expect(fixture.debugElement.queryAll(By.css('op-form-field')).length).toEqual(10);
    expect(fixture.debugElement.queryAll(By.css('op-text-input')).length).toEqual(2);
    expect(fixture.debugElement.queryAll(By.css('op-formattable-textarea-input')).length).toEqual(2);
    expect(fixture.debugElement.queryAll(By.css('op-select-input')).length).toEqual(2);
    expect(fixture.debugElement.queryAll(By.css('op-date-input')).length).toEqual(1);
    expect(fixture.debugElement.queryAll(By.css('op-boolean-input')).length).toEqual(2);
    expect(fixture.debugElement.queryAll(By.css('op-integer-input')).length).toEqual(1);
    expect(fixture.debugElement.query(By.css('button[type=submit]'))).toBeTruthy();
  }));

  it('should get the form schema from @Input settings when present', fakeAsync(() => {
    // @ts-ignore
    dynamicFormService.getSettings.and.returnValue(dynamicFormSettings);

    component.settings = {
      payload: formSchema._embedded.payload,
      schema: formSchema._embedded.schema,
    };

    component.ngOnChanges();

    expect(dynamicFormService.getSettings).toHaveBeenCalled();

    fixture.detectChanges();

    expect(fixture.debugElement.query(By.css('.op-form--container'))).toBeTruthy()
    expect(fixture.debugElement.queryAll(By.css('formly-form')).length).toEqual(1);
    expect(fixture.debugElement.queryAll(By.css('op-form-field')).length).toEqual(10);
    expect(fixture.debugElement.queryAll(By.css('op-text-input')).length).toEqual(2);
    expect(fixture.debugElement.queryAll(By.css('op-formattable-textarea-input')).length).toEqual(2);
    expect(fixture.debugElement.queryAll(By.css('op-select-input')).length).toEqual(2);
    expect(fixture.debugElement.queryAll(By.css('op-date-input')).length).toEqual(1);
    expect(fixture.debugElement.queryAll(By.css('op-boolean-input')).length).toEqual(2);
    expect(fixture.debugElement.queryAll(By.css('op-integer-input')).length).toEqual(1);
    expect(fixture.debugElement.query(By.css('button[type=submit]'))).toBeFalsy();
  }));

  it('should submit the form and notify the user', fakeAsync(() => {
    // @ts-ignore
    dynamicFormService.getSettingsFromBackend$.and.returnValue(defer(() => Promise.resolve(dynamicFormSettings)));
    dynamicFormService.submit$.and.returnValue(defer(() => Promise.resolve('ok')));
    let submitButton;

    // Should not show notifications when showNotifications === false
    component.showNotifications = false;

    component.ngOnChanges();
    flush();
    fixture.detectChanges();
    submitButton = fixture.debugElement.query(By.css('button[type=submit]'));
    submitButton.nativeElement.click();

    flush();

    expect(dynamicFormService.submit$).toHaveBeenCalled();
    expect(notificationsService.addSuccess).not.toHaveBeenCalled();

    // Should not show notifications when showNotifications === true
    component.showNotifications = true;

    fixture.detectChanges();

    submitButton = fixture.debugElement.query(By.css('button[type=submit]'));
    submitButton.nativeElement.click();

    flush();

    expect(dynamicFormService.submit$).toHaveBeenCalled();
    expect(notificationsService.addSuccess).toHaveBeenCalled();

    dynamicFormService.submit$.and.returnValue(defer(() => { throw 'Error' }));

    submitButton.nativeElement.click();

    flush();

    expect(notificationsService.addError).toHaveBeenCalled();

    dynamicFormService.submit$.and.returnValue(defer(() => Promise.resolve('ok')));
  }));

  it('should be able to be used as a FormControl', fakeAsync(() => {
    const testingHostComponentFixture = TestBed.createComponent(DynamicFormsTestingComponent);
    const testingHostComponent = testingHostComponentFixture.componentInstance;
    const testModel = { name: 'testValue' };
    const testModel2 = { name: 'testValue2' };
    const testModel3 = { name: 'testValue3' };
    const formSettings = {
      fields: [
        {
          "type": "textInput",
          "className": "op-form--field inline-edit--field",
          "key": "name",
          "templateOptions": {
            "required": true,
            "label": "Name",
            "type": "text",
            "placeholder": "",
            "disabled": false
          },
        },
      ],
      model: testModel,
      form: new FormGroup({}),
    }
    // @ts-ignore
    dynamicFormService.getSettingsFromBackend$.and.returnValue(defer(() => Promise.resolve(formSettings)));

    // Get @ViewChild(DynamicFormComponent) dynamicFormControl:DynamicFormComponent;
    testingHostComponentFixture.detectChanges();
    // Bootstrap DynamicFormComponent
    testingHostComponent.dynamicFormControl.ngOnChanges();
    flush();
    // Render DynamicFormComponent
    testingHostComponentFixture.detectChanges();

    expect(testingHostComponentFixture.debugElement.query(By.css('op-dynamic-form.ng-untouched.ng-pristine.ng-valid'))).toBeTruthy('should set the default Angular form classes in the element')
    expect(testingHostComponent.dynamicFormControl.form.value).toEqual(testModel, 'should set the initial model in the form control');

    testingHostComponent.control.setValue(testModel2);
    testingHostComponentFixture.detectChanges();

    expect(testingHostComponent.dynamicFormControl.form.value).toEqual(testModel2, 'should set the model in the dynamic form group programmatically');

    const dynamicFormControlInput = testingHostComponentFixture.debugElement.query(By.css('input')).nativeElement as HTMLInputElement;
    dynamicFormControlInput.value = testModel3.name;
    dynamicFormControlInput.dispatchEvent(new Event('input'));

    testingHostComponentFixture.detectChanges();

    expect(testingHostComponent.control.value).toEqual(testModel3, 'should update the model in the form control when a value is inputted');
    expect(testingHostComponent.dynamicFormControl.form.value).toEqual(testModel3, 'should update the model in the dynamic form group when a value is inputted');
    expect(testingHostComponentFixture.debugElement.query(By.css('op-dynamic-form.ng-touched.ng-dirty.ng-valid'))).toBeTruthy('should set the correct Angular form classes in the element');
  }));
});

