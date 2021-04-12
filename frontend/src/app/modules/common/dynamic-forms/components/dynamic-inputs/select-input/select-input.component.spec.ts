import { fakeAsync, flush } from '@angular/core/testing';
import {
  createDynamicInputFixture,
} from "core-app/modules/common/dynamic-forms/spec/helpers";
import { By } from "@angular/platform-browser";
import { of } from "rxjs";

xdescribe('SelectInputComponent', () => {
  let component: SelectInputComponent;
  let fixture: ComponentFixture<SelectInputComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ SelectInputComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(SelectInputComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
    flush();

    expect(dynamicControl.value).toBe(testModel.changedValue);
    expect(dynamicElement.classList.contains('ng-dirty')).toBeTrue();

    // Blur
    dynamicInput.dispatchEvent(new Event('blur'));
    fixture.detectChanges();
    expect(dynamicElement.classList.contains('ng-touched')).toBeTrue();

    // Disabled
    dynamicControl.disable();
    fixture.detectChanges();
    expect(dynamicInput.disabled).toBeTrue();
  }));
});
