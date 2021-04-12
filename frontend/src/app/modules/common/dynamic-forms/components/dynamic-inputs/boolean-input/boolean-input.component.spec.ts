import { fakeAsync } from '@angular/core/testing';
import {
  createDynamicInputFixture,
  testDynamicInputControValueAccessor,
} from "core-app/modules/common/dynamic-forms/spec/helpers";

xdescribe('BooleanInputComponent', () => {
  let component: BooleanInputComponent;
  let fixture: ComponentFixture<BooleanInputComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ BooleanInputComponent ]
    })
    .compileComponents();
  });

    const fixture = createDynamicInputFixture(fieldsConfig, formModel);

    testDynamicInputControValueAccessor(fixture, testModel, 'op-boolean-input input');
  }));
});
