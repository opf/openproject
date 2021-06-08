import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ChangeDetectionStrategy, DebugElement } from '@angular/core';
import { SlideToggleComponent } from './slide-toggle.component';
import { FormsModule } from '@angular/forms';

describe('slide toggler', () => {
  let app:SlideToggleComponent;
  let fixture:ComponentFixture<SlideToggleComponent>;
  let element:DebugElement;

  beforeEach(() => {
    TestBed
      .configureTestingModule({
        declarations: [SlideToggleComponent],
        imports: [FormsModule],
      })
      .overrideComponent(SlideToggleComponent, { set: { changeDetection: ChangeDetectionStrategy.Default } })
      .compileComponents();

    fixture = TestBed.createComponent(SlideToggleComponent);
    app = fixture.debugElement.componentInstance;
    element = fixture.debugElement;
  });


  it('should set the input correctly', (() => {
    app.active = false;
    fixture.detectChanges();

    const container = document.querySelector('.slide-toggle')!;
    expect(container.classList.contains('-active')).toBeFalse();
    expect(document.contains(container)).toBeTruthy();
  }));

  it('should emit the value correctly', (() => {
    app.active = true;
    fixture.detectChanges();

    let container = document.querySelector('.slide-toggle')!;
    expect(container.classList.contains('-active')).toBeTrue();

    app.active = false;
    fixture.detectChanges();

    expect(app.active).toBeFalse();
    container = document.querySelector('.slide-toggle')!;
    expect(container.classList.contains('-active')).toBeFalse();
  }));

});