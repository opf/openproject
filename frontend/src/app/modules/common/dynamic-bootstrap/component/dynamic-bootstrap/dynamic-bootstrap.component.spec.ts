import {
  ComponentFixture,
  fakeAsync,
  TestBed,
  tick,
} from '@angular/core/testing';
import { DynamicBootstrapComponent } from './dynamic-bootstrap.component';
import { ApplicationRef, Component, DebugElement } from '@angular/core';
import { DynamicBootstrapper } from 'core-app/globals/dynamic-bootstrapper';

// Stub component to bootstrap dynamically
@Component({
  selector: 'op-test',
  template: `<div class="dynamic-component-div"></div>`,
})
export class TestComponent {}

// Stub DynamicBootstrapper so we can pass the stub component definition
class TestDynamicBootstrapper extends DynamicBootstrapper {
  static bootstrapOptionalEmbeddable(appRef:ApplicationRef, element:HTMLElement) {
    DynamicBootstrapper.bootstrapOptionalEmbeddable(appRef, element, [{ selector: 'op-test', cls: TestComponent, embeddable: true }]);
  }
}

describe('DynamicBootstrapComponent', () => {
  let component:DynamicBootstrapComponent;
  let fixture:ComponentFixture<DynamicBootstrapComponent>;
  let element:DebugElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [
        DynamicBootstrapComponent,
        TestComponent,
      ]
    })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(DynamicBootstrapComponent);
    component = fixture.componentInstance;
    element = fixture.debugElement;

    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should render HTML strings and bootstrap Angular directives', fakeAsync(() => {
    // Overwrite with the stub dynamicBootstrapper
    component.dynamicBootstrapper = TestDynamicBootstrapper;
    component.HTML = '<op-test></op-test>';

    fixture.detectChanges();
    tick();

    expect(element.nativeElement.querySelector('.dynamic-component-div')).toBeTruthy();
  }));
});
