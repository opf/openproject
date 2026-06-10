import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CUSTOM_ELEMENTS_SCHEMA, DebugElement } from '@angular/core';
import { AttributeHelpTextComponent } from 'core-app/shared/components/attribute-help-texts/attribute-help-text.component';
import { By } from '@angular/platform-browser';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AttributeHelpTextsService } from './attribute-help-text.service';
import { AttributeHelpTextModalService } from './attribute-help-text-modal.service';
import { QuestionIconComponent } from '@openproject/octicons-angular';
import { OpIconComponent } from '../icon/icon.component';

describe('AttributeHelpTextComponent', () => {
  let component:AttributeHelpTextComponent;
  let fixture:ComponentFixture<AttributeHelpTextComponent>;
  let element:DebugElement;

  const serviceStub = {};
  let modalServiceStub:{ show:ReturnType<typeof vi.fn> };
  const i18nStub = { t: (_scope:string | string[], _options?:Record<string, any>) => 'Show help text' };

  beforeEach(async () => {
    modalServiceStub = {
      show: vi.fn().mockName('AttributeHelpTextModalService.show')
    };
    modalServiceStub.show.mockResolvedValue(undefined);

    await TestBed
      .configureTestingModule({
        declarations: [
          AttributeHelpTextComponent,
          OpIconComponent,
        ],
        providers: [
          { provide: AttributeHelpTextsService, useValue: serviceStub },
          { provide: AttributeHelpTextModalService, useValue: modalServiceStub },
          { provide: I18nService, useValue: i18nStub },
        ],
        imports: [
          QuestionIconComponent,
        ],
        schemas: [CUSTOM_ELEMENTS_SCHEMA],
      })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(AttributeHelpTextComponent);
    component = fixture.debugElement.componentInstance;
    component.helpTextId = 1;
    component.attribute = 'subject';
    component.attributeScope = 'Project';
    element = fixture.debugElement;

    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('renders a button', () => {
    const button = element.query(By.css("[role='button']"));

    expect(button).toBeTruthy();
    expect(button.nativeElement.classList.contains('spot-link')).toBe(true);
  });

  it('renders a tooltip', () => {
    const tooltip = element.query(By.css('tool-tip'));

    expect(tooltip).toBeTruthy();
    expect(tooltip.nativeElement.textContent).toEqual('Show help text');
    expect(tooltip.nativeElement.getAttribute('for')).toMatch(/attribute-help-text-component-\d+/);
    expect(tooltip.nativeElement.getAttribute('popover')).toEqual('manual');
    expect(tooltip.nativeElement.dataset.direction).toEqual('sw');
    expect(tooltip.nativeElement.dataset.type).toEqual('label');
  });

  it('renders an icon', () => {
    const icon = element.query(By.directive(QuestionIconComponent));

    expect(icon.nativeElement.getAttribute('size')).toEqual('xsmall');
  });

  it('applies .help-text--entry class', () => {
    const button = element.query(By.css("[role='button']"));

    expect(button.nativeElement.classList.contains('help-text--entry')).toBe(true);
  });

  it('applies an ID', () => {
    const button = element.query(By.css("[role='button']"));

    expect(button.nativeElement.id).toMatch(/attribute-help-text-component-\d+/);
  });

  it('defines a data-qa-help-text-for attribute', () => {
    const button = element.query(By.css("[role='button']"));

    expect(button.nativeElement.dataset.qaHelpTextFor).toEqual('subject');
  });

  it('should call modalService on click', async () => {
    const button = element.query(By.css("[role='button']"));
    button.nativeElement.click();

    fixture.detectChanges();

    expect(button.nativeElement.ariaDisabled).toEqual('true');

    await Promise.resolve();
    await modalServiceStub.show.mock.results.at(-1)!.value;
    await new Promise(resolve => setTimeout(resolve, 0));
    fixture.detectChanges();

    expect(modalServiceStub.show).toHaveBeenCalledTimes(1);

    expect(modalServiceStub.show).toHaveBeenCalledWith('1');
    expect(button.nativeElement.ariaDisabled).toEqual('false');
  });

  it('should call modalService only once', async () => {
    const button = element.query(By.css("[role='button']"));
    button.nativeElement.click();

    fixture.detectChanges();

    expect(button.nativeElement.ariaDisabled).toEqual('true');

    button.nativeElement.click();
    button.triggerEventHandler('keydown.enter');
    button.triggerEventHandler('keydown.space');

    fixture.detectChanges();
    await Promise.resolve();
    await modalServiceStub.show.mock.results.at(-1)!.value;
    await new Promise(resolve => setTimeout(resolve, 0));
    fixture.detectChanges();

    expect(modalServiceStub.show).toHaveBeenCalledTimes(1);

    expect(modalServiceStub.show).toHaveBeenCalledWith('1');
    expect(button.nativeElement.ariaDisabled).toEqual('false');
  });
});
