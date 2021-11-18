import {
  ComponentFixture,
  TestBed,
} from '@angular/core/testing';
import {
  ChangeDetectionStrategy,
  Component,
  DebugElement,
  ElementRef,
  Input,
  Type,
} from '@angular/core';
import { DatasetInputs } from 'core-app/shared/components/dataset-inputs.decorator';

@Component({
  selector: 'op-test-input',
  template: '<op-test [foo]="bar"></op-test>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TestInputComponent {
  bar = 'foo';
}

@Component({
  selector: 'op-test-data',
  template: `<op-test data-foo='"input from data"'></op-test>`,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TestDataComponent {
}

@DatasetInputs
@Component({
  selector: 'op-test',
  template: '<span [textContent]="foo"></span>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TestComponent {
  @Input() foo:string;

  constructor(readonly elementRef:ElementRef<HTMLElement>) {}
}

fdescribe('DatasetInputs decorator', () => {
  let fixture:ComponentFixture<unknown>;
  let element:DebugElement;
  let htmlElement:HTMLElement;

  const setup = async (componentClass:Type<unknown>) => {
    console.log("SETUP")
    await TestBed.configureTestingModule({
      declarations: [
        TestComponent,
        TestInputComponent,
        TestDataComponent,
      ],
    })
      .compileComponents();

    fixture = TestBed.createComponent(componentClass);
    element = fixture.debugElement;
    htmlElement = element.nativeElement as HTMLElement;

    fixture.detectChanges();
  };

  describe('with an input', () => {
    beforeEach(async () => {
      await setup(TestInputComponent);
    });

    it('renders the input', () => {
      expect(htmlElement.querySelector('op-test-input op-test span')?.textContent)
        .toEqual('foo', 'Expected op-test with a span[textContent=foo]');
    });
  });

  describe('with a data field', () => {
    beforeEach(async () => {
      await setup(TestDataComponent);
    });

    it('renders the input', () => {
      expect(htmlElement.querySelector('op-test-input op-test span')?.textContent)
        .toEqual('input from data', 'Expected op-test with a span[textContent=input from data]');
    });
  });
});
