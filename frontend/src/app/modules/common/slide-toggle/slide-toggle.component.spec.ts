import { ComponentFixture, fakeAsync, TestBed, async } from '@angular/core/testing';
import { DebugElement, NO_ERRORS_SCHEMA } from '@angular/core';
import { SlideToggleComponent } from './slide-toggle.component';
import {FormsModule} from '@angular/forms';

describe('slide toggler', () => {
  let app:SlideToggleComponent;
  let fixture:ComponentFixture<SlideToggleComponent>;
  let element:DebugElement;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [SlideToggleComponent],
      imports: [ FormsModule ],
    }).compileComponents();

    fixture = TestBed.createComponent(SlideToggleComponent);
    app = fixture.debugElement.componentInstance;
    element = fixture.debugElement;
  });


  it('should set the input correctly', async(() => {
    app.filterName = 'foo';
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      let container = document.querySelector('#div-values-foo');
      expect(document.contains(container)).toBeTruthy();
    });
  }));

  it('should emit the value correctly', async(() => {
    app.filterValue = true;
    fixture.detectChanges();
    fixture.whenStable().then(() => {
        let slider = document.querySelector('.slider');
        if (slider) {
            let style = getComputedStyle(slider);
            let backgroundColor = style.backgroundColor;
            expect(backgroundColor).toBe('rgb(0, 0, 139)');
            app.filterValue = false;
            fixture.detectChanges();
            setTimeout(() => {
            style = getComputedStyle(slider!!);
            backgroundColor = style.backgroundColor;
            expect(backgroundColor).toBe('rgb(204, 204, 204)'); }, 1000);
        }
    });
  }));

});