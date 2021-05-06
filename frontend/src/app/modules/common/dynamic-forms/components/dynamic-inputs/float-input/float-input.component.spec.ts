import { fakeAsync } from '@angular/core/testing';
import {
  createDynamicInputFixture,
  testDynamicInputControValueAccessor,
} from "core-app/modules/common/dynamic-forms/spec/helpers";

describe('FloatInputComponent', () => {
  it('should load the field', fakeAsync(() => {
    const fieldsConfig = [
      {
        "type": "floatInput" as "floatInput",
        "className": "op-form--field inline-edit--field",
        "key": "testControl",
        "templateOptions": {
          "required": true,
          "label": "testControl",
        },
      }
    ];
    const formModel = {
      testControl: 'testValue',
    };
    const testModel = {
      initialValue: formModel.testControl,
      changedValue: 'testValue2',
    };

    const fixture = createDynamicInputFixture(fieldsConfig, formModel);

    testDynamicInputControValueAccessor(fixture, testModel, 'op-float-input input');
  }));
});

