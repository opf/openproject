import { fakeAsync } from '@angular/core/testing';
import {
  createDynamicInputFicture,
  testDynamicInputControValueAccessor,
} from "core-app/modules/common/dynamic-forms/spec/helpers";

describe('TextComponent', () => {
  it('should load the field', fakeAsync(() => {
    const fieldsConfig = [
      {
        "type": "textInput" as "textInput",
        "className": "op-form--field inline-edit--field",
        "key": "testControl",
        "templateOptions": {
          "required": true,
          "label": "testControl",
          "type": "text",
          "placeholder": "",
          "disabled": false
        },
      }
    ];
    const formModel = {
      testControl: 'testValue',
    };
    const testModel = {
      initialValue: 'testValue',
      changedValue: 'testValue2',
    };

    const fixture = createDynamicInputFicture(fieldsConfig, formModel);

    testDynamicInputControValueAccessor(fixture, testModel, 'op-text-input input');
  }));
});
