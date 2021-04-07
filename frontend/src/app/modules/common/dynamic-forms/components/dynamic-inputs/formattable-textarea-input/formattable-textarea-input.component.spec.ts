import { ComponentFixture, TestBed } from '@angular/core/testing';

import { FormattableTextareaInputComponent } from './formattable-textarea-input.component';

describe('FormattableTextareaInputComponent', () => {
  let component: FormattableTextareaInputComponent;
  let fixture: ComponentFixture<FormattableTextareaInputComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ FormattableTextareaInputComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(FormattableTextareaInputComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
