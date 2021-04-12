import { fakeAsync } from '@angular/core/testing';
import {
  createDynamicInputFixture,
  testDynamicInputControValueAccessor,
} from "core-app/modules/common/dynamic-forms/spec/helpers";

xdescribe('IntegerInputComponent', () => {
  let component: IntegerInputComponent;
  let fixture: ComponentFixture<IntegerInputComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ IntegerInputComponent ]
    })
    .compileComponents();
  });

    const fixture = createDynamicInputFixture(fieldsConfig, formModel);

    testDynamicInputControValueAccessor(fixture, testModel, 'op-integer-input input');
  }));
});

