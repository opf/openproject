import { NgSelectModule } from '@ng-select/ng-select';
import { NgOptionHighlightModule } from '@ng-select/ng-option-highlight';
import {
  Component,
  forwardRef,
  ViewChild,
} from '@angular/core';
import {
  ComponentFixture,
  fakeAsync,
  flush,
  TestBed,
} from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import {
  defer,
  of,
} from 'rxjs';
import {
  NG_VALUE_ACCESSOR,
  ReactiveFormsModule,
  UntypedFormControl,
  UntypedFormGroup,
} from '@angular/forms';
import { CommonModule } from '@angular/common';
import { FormlyModule } from '@ngx-formly/core';
import { DynamicFormComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-form/dynamic-form.component';
import { DynamicFormService } from 'core-app/shared/components/dynamic-forms/services/dynamic-form/dynamic-form.service';
import { DynamicFieldsService } from 'core-app/shared/components/dynamic-forms/services/dynamic-fields/dynamic-fields.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { TextInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/text-input/text-input.component';
import { IntegerInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/integer-input/integer-input.component';
import { SelectInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/select-input/select-input.component';
import { BooleanInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/boolean-input/boolean-input.component';
import { DateInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/date-input/date-input.component';
import { FormattableTextareaInputComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-inputs/formattable-textarea-input/formattable-textarea-input.component';
import { DynamicFieldGroupWrapperComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-field-group-wrapper/dynamic-field-group-wrapper.component';
import { SpotFormFieldComponent } from 'core-app/spot/components/form-field/form-field.component';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { DynamicFieldWrapperComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-field-wrapper/dynamic-field-wrapper.component';
import { ConfirmDialogService } from "core-app/shared/components/modals/confirm-dialog/confirm-dialog.service";

@Component({
  template: `
    <op-dynamic-form [formControl]="control"></op-dynamic-form>`,
  providers: [],
})
class DynamicFormsTestingComponent {
  control = new UntypedFormControl('');

  @ViewChild(DynamicFormComponent) dynamicFormControl:DynamicFormComponent;
}

describe('DynamicFormComponent', () => {
  let component:DynamicFormComponent;
  let fixture:ComponentFixture<DynamicFormComponent>;
  const formSchema:any = {
    _type: 'Form',
    _embedded: {
      payload: {
        name: 'Project 1',
        _links: {
          parent: {
            href: '/api/v3/projects/26',
            title: 'Parent project',
          },
        },
      },
      schema: {
        _type: 'Schema',
        _dependencies: [],
        name: {
          type: 'String',
          name: 'Name',
          required: true,
          hasDefault: false,
          writable: true,
          minLength: 1,
          maxLength: 255,
          options: {},
        },
        parent: {
          type: 'Project',
          name: 'Subproject of',
          required: false,
          hasDefault: false,
          writable: true,
          _links: {
            allowedValues: {
              href: '/api/v3/projects/available_parent_projects?of=25',
            },
          },
        },
        _links: {},
      },
      validationErrors: {},
    },
    _links: {
      self: {
        href: '/api/v3/projects/25/form',
        method: 'post',
      },
      validate: {
        href: '/api/v3/projects/25/form',
        method: 'post',
      },
      commit: {
        href: '/api/v3/projects/25',
        method: 'patch',
      },
    },
  };
  const dynamicFormSettings:any = {
    fields: [
      {
        type: 'textInput',
        key: 'name',
        templateOptions: {
          required: true,
          label: 'Name',
          type: 'text',
          placeholder: '',
          disabled: false,
        },
      },
      {
        type: 'integerInput',
        key: 'quantity',
        templateOptions: {
          required: true,
          label: 'Quantity',
          type: 'number',
          placeholder: '',
          disabled: false,
        },
      },
      {
        type: 'textInput',
        key: 'identifier',
        templateOptions: {
          required: true,
          label: 'Identifier',
          type: 'text',
          placeholder: '',
          disabled: false,
        },
      },
      {
        type: 'formattableInput',
        key: 'description',
        templateOptions: {
          required: false,
          label: 'Description',
          editorType: 'full',
          inlineLabel: true,
          placeholder: '',
          disabled: false,
        },
      },
      {
        type: 'booleanInput',
        key: 'public',
        templateOptions: {
          required: true,
          label: 'Public',
          type: 'checkbox',
          placeholder: '',
          disabled: false,
        },
      },
      {
        type: 'booleanInput',
        key: 'active',
        templateOptions: {
          required: true,
          label: 'Active',
          type: 'checkbox',
          placeholder: '',
          disabled: false,
        },
      },
      {
        type: 'selectInput',
        expressionProperties: {},
        key: 'status',
        templateOptions: {
          required: false,
          label: 'Status',
          type: 'number',
          locale: 'en',
          bindLabel: 'title',
          searchable: false,
          virtualScroll: true,
          typeahead: false,
          clearOnBackspace: false,
          clearSearchOnAdd: false,
          hideSelected: false,
          text: {
            add_new_action: 'Create',
          },
          placeholder: '',
          disabled: false,
          clearable: true,
          multiple: false,
        },
      },
      {
        type: 'formattableInput',
        key: 'statusExplanation',
        templateOptions: {
          required: false,
          label: 'Status description',
          editorType: 'full',
          inlineLabel: true,
          placeholder: '',
          disabled: false,
        },
      },
      {
        type: 'selectInput',
        expressionProperties: {},
        key: '_links.parent',
        templateOptions: {
          required: false,
          label: 'Subproject of',
          type: 'number',
          locale: 'en',
          bindLabel: 'title',
          searchable: false,
          virtualScroll: true,
          typeahead: false,
          clearOnBackspace: false,
          clearSearchOnAdd: false,
          hideSelected: false,
          text: {
            add_new_action: 'Create',
          },
          options: of([]),
        },
      },
      {
        type: 'dateInput',
        key: 'customField12',
        templateOptions: {
          required: false,
          label: 'Date',
          placeholder: '',
          disabled: false,
        },
      },
    ],
    model: {
      identifier: 'test11',
      name: 'qwe',
      active: true,
      public: false,
      description: {
        format: 'markdown',
        raw: 'asdadsad',
        html: '<p class="op-uc-p">asdadsad</p>',
      },
      status: null,
      statusExplanation: {
        format: 'markdown',
        raw: null,
        html: '',
      },
      customField12: null,
      _links: {
        parent: {
          href: '/api/v3/projects/23',
          title: 'qweqwe',
          name: 'qweqwe',
        },
      },
    },
    form: new UntypedFormGroup({}),
  };
  const I18nServiceStub = {
    t(key:string) {
      return 'test translation';
    },
  };
  const apiV3Base = 'http://www.openproject.com/api/v3/';
  const IPathHelperServiceStub = { api: { v3: { apiV3Base } } };
  let toastService:jasmine.SpyObj<ToastService>;
  let dynamicFormService:jasmine.SpyObj<DynamicFormService>;

  beforeEach(async () => {
    const toastServiceSpy = jasmine.createSpyObj('ToastService', ['addError', 'addSuccess']);
    const dynamicFormServiceSpy = jasmine.createSpyObj('DynamicFormService', ['getSettings', 'getSettingsFromBackend$', 'registerForm', 'submit$']);
    const confirmDialogServiceSpy = jasmine.createSpyObj('ConfirmDialogService', ['confirm']);

    await TestBed
      .configureTestingModule({
        imports: [
          CommonModule,
          HttpClientTestingModule,
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
                name: 'op-dynamic-field-group-wrapper',
                component: DynamicFieldGroupWrapperComponent,
              },
              {
                name: 'op-dynamic-field-wrapper',
                component: DynamicFieldWrapperComponent,
              },
            ],
          }),
          NgSelectModule,
          NgOptionHighlightModule,
        ],
        declarations: [
          DynamicFormComponent,
          SpotFormFieldComponent,
          TextInputComponent,
          IntegerInputComponent,
          SelectInputComponent,
          BooleanInputComponent,
          DynamicFormsTestingComponent,
          DynamicFieldGroupWrapperComponent,
          DynamicFieldWrapperComponent,
          // Skip adding DateInputComponent and FormattableTextareaInputComponent
          // to keep it simple (inheritance test issues).
        ],
        providers: [
          DynamicFieldsService,
          { provide: I18nService, useValue: I18nServiceStub },
          { provide: PathHelperService, useValue: IPathHelperServiceStub },
          { provide: ToastService, useValue: toastServiceSpy },
          { provide: ConfirmDialogService, useValue: confirmDialogServiceSpy },
        ],
      })
      // Set component providers
      .overrideComponent(
        DynamicFormComponent,
        {
          set: {
            providers: [
              {
                provide: DynamicFormService,
                useValue: dynamicFormServiceSpy,
              },
              {
                provide: NG_VALUE_ACCESSOR,
                multi: true,
                useExisting: forwardRef(() => DynamicFormComponent),
              },
            ],
          },
        },
      )
      .compileComponents();

    fixture = TestBed.createComponent(DynamicFormComponent);
    component = fixture.componentInstance;
    toastService = fixture.debugElement.injector.get(ToastService) as jasmine.SpyObj<ToastService>;
    dynamicFormService = fixture.debugElement.injector.get(DynamicFormService) as jasmine.SpyObj<DynamicFormService>;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should get the form schema from the backend when no @Input settings', fakeAsync(() => {
    // @ts-ignore
    dynamicFormService.getSettingsFromBackend$.and.returnValue(defer(() => Promise.resolve(dynamicFormSettings)));

    component.resourcePath = '/api/v3/projects/1234/form';
    component.ngOnChanges({ resourcePath: { currentValue: '/api/v3/projects/1234/form' } } as any);

    expect(dynamicFormService.getSettingsFromBackend$).toHaveBeenCalled();

    fixture.detectChanges();
    flush();

    expect(fixture.debugElement.query(By.css('[data-qa="op-form--container"]'))).toBeTruthy();
    expect(fixture.debugElement.queryAll(By.css('formly-form')).length).toEqual(1);
    expect(fixture.debugElement.queryAll(By.css('formly-field')).length).toEqual(10);
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

    component.resourcePath = '/api/v3/projects/1234/form';
    component.settings = {
      payload: formSchema._embedded.payload,
      schema: formSchema._embedded.schema,
    };

    component.ngOnChanges({ settings: { currentValue: component.settings } } as any);

    expect(dynamicFormService.getSettings).toHaveBeenCalled();

    fixture.detectChanges();

    expect(fixture.debugElement.query(By.css('[data-qa="op-form--container"]'))).toBeTruthy();
    expect(fixture.debugElement.queryAll(By.css('formly-form')).length).toEqual(1);
    expect(fixture.debugElement.queryAll(By.css('formly-field')).length).toEqual(10);
    expect(fixture.debugElement.queryAll(By.css('op-text-input')).length).toEqual(2);
    expect(fixture.debugElement.queryAll(By.css('op-formattable-textarea-input')).length).toEqual(2);
    expect(fixture.debugElement.queryAll(By.css('op-select-input')).length).toEqual(2);
    expect(fixture.debugElement.queryAll(By.css('op-date-input')).length).toEqual(1);
    expect(fixture.debugElement.queryAll(By.css('op-boolean-input')).length).toEqual(2);
    expect(fixture.debugElement.queryAll(By.css('op-integer-input')).length).toEqual(1);
    expect(fixture.debugElement.query(By.css('button[type=submit]'))).toBeTruthy();
  }));

  it('should submit the form and notify the user', fakeAsync(() => {
    // @ts-ignore
    dynamicFormService.getSettingsFromBackend$.and.returnValue(defer(() => Promise.resolve(dynamicFormSettings)));
    dynamicFormService.submit$.and.returnValue(defer(() => Promise.resolve('ok')));
    let submitButton;

    // Should not show notifications when showNotifications === false
    component.showNotifications = false;

    component.resourcePath = '/api/v3/projects/1234/form';
    component.ngOnChanges({ resourcePath: { currentValue: '/api/v3/projects/1234/form' } } as any);
    flush();
    fixture.detectChanges();
    submitButton = fixture.debugElement.query(By.css('button[type=submit]'));
    submitButton.nativeElement.click();

    flush();

    expect(dynamicFormService.submit$).toHaveBeenCalled();
    expect(toastService.addSuccess).not.toHaveBeenCalled();

    // Should not show notifications when showNotifications === true
    component.showNotifications = true;

    fixture.detectChanges();

    submitButton = fixture.debugElement.query(By.css('button[type=submit]'));
    submitButton.nativeElement.click();

    flush();

    expect(dynamicFormService.submit$).toHaveBeenCalled();
    expect(toastService.addSuccess).toHaveBeenCalled();

    dynamicFormService.submit$.and.returnValue(defer(() => {
      throw new Error('Error');
    }));

    submitButton.nativeElement.click();

    flush();

    expect(toastService.addError).toHaveBeenCalled();

    dynamicFormService.submit$.and.returnValue(defer(() => Promise.resolve('ok')));
  }));

  // Moving the DynamicForm.form assignment out of the _setupDynamicForm breaks the
  // expressionProperties execution
  it('should run expressionProperties', fakeAsync(() => {
    const [firstField, ...restOfFields] = dynamicFormSettings.fields;
    const expressionPropertiesSpy = jasmine.createSpy('expressionPropertiesSpy');
    const firstFieldCopy = {
      ...firstField,
      expressionProperties: {
        'templateOptions.test': expressionPropertiesSpy,
      },
    };
    const dynamicFormSettingsForSubmit = {
      ...dynamicFormSettings,
      fields: [
        firstFieldCopy,
        ...restOfFields,
      ],
    };
    // @ts-ignore
    dynamicFormService.getSettingsFromBackend$.and.returnValue(defer(() => Promise.resolve(dynamicFormSettingsForSubmit)));
    dynamicFormService.submit$.and.returnValue(defer(() => Promise.resolve('ok')));

    component.resourcePath = '/api/v3/projects/1234/form';
    component.ngOnChanges({ resourcePath: { currentValue: '/api/v3/projects/1234/form' } } as any);
    flush();
    fixture.detectChanges();
    const submitButton = fixture.debugElement.query(By.css('button[type=submit]'));
    submitButton.nativeElement.click();

    flush();

    expect(expressionPropertiesSpy).toHaveBeenCalled();
  }));
});
