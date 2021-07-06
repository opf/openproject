import { fakeAsync } from '@angular/core/testing';
import {
  createDynamicInputFixture,
  testDynamicInputControValueAccessor,
} from 'core-app/shared/components/dynamic-forms/spec/helpers';

describe('TextInputComponent', () => {
  it('should load the field', fakeAsync(() => {
    const fieldsConfig = [
      {
        type: 'textInput' as const,
        key: 'testControl',
        templateOptions: {
          required: true,
          label: 'testControl',
          type: 'text',
          placeholder: '',
          disabled: false,
        },
      },
    ];
    const formModel = {
      testControl: 'testValue',
    };
    const testModel = {
      initialValue: 'testValue',
      changedValue: 'testValue2',
    };

    const fixture = createDynamicInputFixture(fieldsConfig, formModel);

    testDynamicInputControValueAccessor(fixture, testModel, 'op-text-input input');
  }));
});
