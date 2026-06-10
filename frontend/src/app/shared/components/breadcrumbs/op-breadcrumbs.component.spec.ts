import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BreadcrumbItem, OpBreadcrumbsComponent } from './op-breadcrumbs.component';

describe('OpBreadcrumbsComponent', () => {
  let fixture:ComponentFixture<OpBreadcrumbsComponent>;
  let component:OpBreadcrumbsComponent;

  const i18nStub = { t: (_key:string) => 'Breadcrumb' };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [
        OpBreadcrumbsComponent,
      ],
      providers: [
        { provide: I18nService, useValue: i18nStub },
      ],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
    }).compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(OpBreadcrumbsComponent);
    component = fixture.componentInstance;
  });

  it('reuses breadcrumb nodes for equivalent items with new object identities', () => {
    component.items = [
      { href: '/projects/sp', text: 'SP' },
      { href: '/projects/sp/boards', text: 'Boards' },
      { href: '/projects/sp/boards/48', text: 'Board 48' },
    ];

    fixture.detectChanges();

    const originalItems = breadcrumbItems();

    component.items = [
      { href: '/projects/sp', text: 'SP' },
      { href: '/projects/sp/boards', text: 'Boards' },
      { href: '/projects/sp/boards/48', text: 'Board 48' },
    ];

    fixture.detectChanges();

    const updatedItems = breadcrumbItems();

    expect(updatedItems[0].nativeElement).toBe(originalItems[0].nativeElement);
    expect(updatedItems[1].nativeElement).toBe(originalItems[1].nativeElement);
    expect(updatedItems[2].nativeElement).toBe(originalItems[2].nativeElement);
  });

  it('keeps unchanged breadcrumb nodes when only the current item changes', () => {
    component.items = [
      { href: '/projects/sp', text: 'SP' },
      { href: '/projects/sp/boards', text: 'Boards' },
      'Old board name',
    ];

    fixture.detectChanges();

    const originalItems = breadcrumbItems();

    component.items = [
      { href: '/projects/sp', text: 'SP' },
      { href: '/projects/sp/boards', text: 'Boards' },
      'New board name',
    ];

    fixture.detectChanges();

    const updatedItems = breadcrumbItems();

    expect(updatedItems[0].nativeElement).toBe(originalItems[0].nativeElement);
    expect(updatedItems[1].nativeElement).toBe(originalItems[1].nativeElement);
  });

  it('keeps linked breadcrumb nodes when only the text changes', () => {
    component.items = [
      { href: '/projects/sp', text: 'Old project name' },
      { href: '/projects/sp/boards', text: 'Boards' },
      'Board 48',
    ];

    fixture.detectChanges();

    const originalItems = breadcrumbItems();

    component.items = [
      { href: '/projects/sp', text: 'New project name' },
      { href: '/projects/sp/boards', text: 'Boards' },
      'Board 48',
    ];

    fixture.detectChanges();

    const updatedItems = breadcrumbItems();

    expect(updatedItems[0].nativeElement).toBe(originalItems[0].nativeElement);
    expect(updatedItems[1].nativeElement).toBe(originalItems[1].nativeElement);
    expect(updatedItems[2].nativeElement).toBe(originalItems[2].nativeElement);
  });

  it('builds stable tracking keys from breadcrumb values', () => {
    const link:BreadcrumbLink = { href: '/projects/sp', text: 'SP' };

    expect(component.trackBreadcrumbItem(1, link))
      .toEqual('link:/projects/sp:1');
    expect(component.trackBreadcrumbItem(2, 'Board 48'))
      .toEqual('text:Board 48:2');
  });

  function breadcrumbItems() {
    return fixture.debugElement.queryAll(By.css('[data-test-selector="op-breadcrumbs--item"]'));
  }
});

type BreadcrumbLink = Extract<BreadcrumbItem, { href:string; text:string }>;
