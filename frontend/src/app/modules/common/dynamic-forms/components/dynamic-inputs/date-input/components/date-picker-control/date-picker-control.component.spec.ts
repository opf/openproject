import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DatePickerControlComponent } from './date-picker-control.component';

xdescribe('DatePickerAdapterComponent', () => {
  let component: DatePickerControlComponent;
  let fixture: ComponentFixture<DatePickerControlComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ DatePickerControlComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(DatePickerControlComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
