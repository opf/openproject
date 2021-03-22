import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DatePickerAdapterComponent } from './date-picker-adapter.component';

describe('DatePickerAdapterComponent', () => {
  let component: DatePickerAdapterComponent;
  let fixture: ComponentFixture<DatePickerAdapterComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ DatePickerAdapterComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(DatePickerAdapterComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
