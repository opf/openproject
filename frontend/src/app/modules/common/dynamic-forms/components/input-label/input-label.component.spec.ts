import { ComponentFixture, TestBed } from '@angular/core/testing';

import { InputLabelComponent } from './input-label.component';

describe('InputLabelComponent', () => {
  let component: InputLabelComponent;
  let fixture: ComponentFixture<InputLabelComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ InputLabelComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(InputLabelComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
