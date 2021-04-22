import { ComponentFixture, TestBed } from "@angular/core/testing";
import { Component, ViewChild } from "@angular/core";
import { FormGroup, ReactiveFormsModule } from "@angular/forms";
import { CommonModule } from "@angular/common";
import { TextInputComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/text-input/text-input.component";
import { IntegerInputComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/integer-input/integer-input.component";
import { SelectInputComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/select-input/select-input.component";
import { BooleanInputComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/boolean-input/boolean-input.component";
import { DateInputComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/date-input/date-input.component";
import { FormattableTextareaInputComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-inputs/formattable-textarea-input/formattable-textarea-input.component";
import { DynamicFieldGroupWrapperComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-field-group-wrapper/dynamic-field-group-wrapper.component";
import { NgSelectModule } from "@ng-select/ng-select";
import { NgOptionHighlightModule } from "@ng-select/ng-option-highlight";
import { FormlyModule } from "@ngx-formly/core";
import { IOPFormlyFieldSettings } from "core-app/modules/common/dynamic-forms/typings";
import { FormlyField } from "@ngx-formly/core";
import { OpFormFieldComponent } from "core-app/modules/common/form-field/form-field.component";
import { By } from "@angular/platform-browser";
export function createDynamicInputFixture(fields: IOPFormlyFieldSettings[], model:any, providers?:any[]): ComponentFixture<any> {

  @Component({
    template:`
      <form [formGroup]="form">
        <formly-form [form]="form"
                     [model]="model"
                     [fields]="fields">
          <ng-template formlyTemplate let-field>
            <op-form-field *ngFor="let field of fields"
                           [label]="field.templateOptions?.label"
                           [noWrapLabel]="field.templateOptions?.noWrapLabel"
                           [required]="field.templateOptions?.required">
              <formly-field [field]="field" slot=input></formly-field>
    
              <formly-validation-message [field]="field" slot=errors></formly-validation-message>
            </op-form-field>
          </ng-template>
        </formly-form>
      </form>      
    `,
    providers,
  })
  class DynamicInputsTestingComponent {
    form = new FormGroup({});
    model = model;
    fields = fields;

    @ViewChild(FormlyField) dynamicControl:FormlyField;
  }

  TestBed
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
        TextInputComponent,
        IntegerInputComponent,
        SelectInputComponent,
        BooleanInputComponent,
        OpFormFieldComponent,
        DateInputComponent,
        FormattableTextareaInputComponent,
        DynamicInputsTestingComponent,
      ],
      providers: []
    })

  TestBed.compileComponents();

  const fixture = TestBed.createComponent(DynamicInputsTestingComponent);
  fixture.detectChanges();

  return fixture;
}

export function testDynamicInputControValueAccessor(fixture:ComponentFixture<any>, model:any, selector:string) {
  const dynamicControl = fixture.componentInstance.dynamicControl.field.formControl;
  const dynamicInput = fixture.debugElement.query(By.css(selector)).nativeElement;

  // Test ControlValueAccessor
  // Write Value
  expect(dynamicControl.value).toBe(model.initialValue);
  expect(dynamicInput.classList.contains('ng-untouched')).toBeTrue();
  expect(dynamicInput.classList.contains('ng-valid')).toBeTrue();
  expect(dynamicInput.classList.contains('ng-pristine')).toBeTrue();

  // Change
  if (dynamicInput.type === 'checkbox') {
    dynamicInput.click();
  } else {
    dynamicInput.value = model.changedValue;
    dynamicInput.dispatchEvent(new Event('input'));
  }

  fixture.detectChanges();

  expect(dynamicControl.value).toBe(model.changedValue);
  expect(dynamicInput.classList.contains('ng-dirty')).toBeTrue();

  // Blur
  dynamicInput.dispatchEvent(new Event('blur'));
  fixture.detectChanges();
  expect(dynamicInput.classList.contains('ng-touched')).toBeTrue();

  // Disabled
  dynamicControl.disable();
  fixture.detectChanges();
  expect(dynamicInput.disabled).toBeTrue();
}