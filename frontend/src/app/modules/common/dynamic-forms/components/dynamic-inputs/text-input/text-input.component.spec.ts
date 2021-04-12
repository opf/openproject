import { fakeAsync } from '@angular/core/testing';
import {
  createDynamicInputFixture,
  testDynamicInputControValueAccessor,
} from "core-app/modules/common/dynamic-forms/spec/helpers";

xdescribe('TextComponent', () => {
  let component: TextInputComponent;
  let fixture: ComponentFixture<TextInputComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ TextInputComponent ]
    })
    .compileComponents();
  });

    const fixture = createDynamicInputFixture(fieldsConfig, formModel);

    testDynamicInputControValueAccessor(fixture, testModel, 'op-text-input input');
  }));
});
