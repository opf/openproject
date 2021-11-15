import { ComponentFixture, TestBed } from '@angular/core/testing';

import { FormattableControlComponent } from './formattable-control.component';

xdescribe('FormattableControlComponent', () => {
  let component:FormattableControlComponent;
  let fixture:ComponentFixture<FormattableControlComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [FormattableControlComponent],
    })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(FormattableControlComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
