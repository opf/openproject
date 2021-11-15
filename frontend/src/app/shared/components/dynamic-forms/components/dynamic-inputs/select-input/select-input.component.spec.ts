import { fakeAsync, flush } from '@angular/core/testing';
import { createDynamicInputFixture } from 'core-app/shared/components/dynamic-forms/spec/helpers';
import { By } from '@angular/platform-browser';
import { of } from 'rxjs';

describe('SelectInputComponent', () => {
  it('should load the field', fakeAsync(() => {
    const selectOptions = [
      {
        name: 'option1',
        value: 1,
      },
      {
        name: 'option2',
        value: 2,
      },
    ];
    const fieldsConfig = [
      {
        type: 'selectInput' as const,
        key: 'testControl',
        templateOptions: {
          required: true,
          label: 'testControl',
          type: 'text',
          placeholder: '',
          disabled: false,
          options: of(selectOptions),
          bindLabel: 'name',
          bindValue: 'value',
        },
      },
    ];
    const formModel = {
      testControl: selectOptions[0],
    };
    const testModel = {
      initialValue: selectOptions[0],
      changedValue: selectOptions[1],
    };
    const fixture = createDynamicInputFixture(fieldsConfig, formModel);
    const dynamicForm = fixture.componentInstance.dynamicForm.field.formControl;
    const dynamicInput = fixture.debugElement.query(By.css('op-select-input input')).nativeElement;
    const dynamicDebugElement = fixture.debugElement.query(By.css('ng-select'));
    const dynamicElement = dynamicDebugElement.nativeElement;

    // Test ControlValueAccessor
    // Write Value
    expect(dynamicForm.value.testControl).toBe(testModel.initialValue);
    expect(dynamicElement.classList.contains('ng-untouched')).toBeTrue();
    expect(dynamicElement.classList.contains('ng-valid')).toBeTrue();
    expect(dynamicElement.classList.contains('ng-pristine')).toBeTrue();

    // Change
    // Select second option
    dynamicDebugElement.triggerEventHandler('keydown', {
      which: 40, // ArrowDown
      key: '',
      preventDefault: () => { },
    });
    dynamicDebugElement.triggerEventHandler('keydown', {
      which: 40, // ArrowDown
      key: '',
      preventDefault: () => { },
    });
    dynamicDebugElement.triggerEventHandler('keydown', {
      which: 13, // Enter key
      key: '',
      preventDefault: () => { },
    });

    fixture.detectChanges();
    flush();

    expect(dynamicForm.value.testControl).toBe(testModel.changedValue);
    expect(dynamicElement.classList.contains('ng-dirty')).toBeTrue();

    // Blur
    dynamicInput.dispatchEvent(new Event('blur'));
    fixture.detectChanges();
    expect(dynamicElement.classList.contains('ng-touched')).toBeTrue();

    // Disabled
    dynamicForm.disable();
    fixture.detectChanges();
    expect(dynamicInput.disabled).toBeTrue();
  }));
});
