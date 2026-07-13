import type { Mock } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { States } from 'core-app/core/states/states.service';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { ChangeDetectionStrategy, Component, NO_ERRORS_SCHEMA } from '@angular/core';
import { of, map } from 'rxjs';
import { NgSelectModule } from '@ng-select/ng-select';

import { OpAutocompleterComponent } from './op-autocompleter.component';
import { By } from '@angular/platform-browser';
import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';

@Component({
  selector: 'op-test-autocompleter',
  template: '',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
class TestAutocompleterComponent extends OpAutocompleterComponent {
}

describe('autocompleter', () => {
  let fixture:ComponentFixture<OpAutocompleterComponent>;
  let getOptionsFnSpy:Mock;
  const workPackagesStub = [
    {
      id: 1,
      subject: 'Workpackage 1',
      name: 'Workpackage 1',
      formattedId: '#1',
      author: {
        href: '/api/v3/users/1',
        name: 'Author1',
      },
      type: { id: 1, name: 'Task' },
      status: { id: 1, name: 'Open' },
      project: { name: 'My Project' },
      description: {
        format: 'markdown',
        raw: 'Description of WP1',
        html: '<p>Description of WP1</p>',
      },
      createdAt: '2021-03-26T10:42:14Z',
      updatedAt: '2021-03-26T10:42:14Z',
      dueDate: '2021-03-26T10:42:14Z',
      startDate: '2021-03-26T10:42:14Z',
    },
    {
      id: 2,
      subject: 'Workpackage 2',
      name: 'Workpackage 2',
      formattedId: 'PROJ-2',
      author: {
        href: '/api/v3/users/2',
        name: 'Author2',
      },
      type: { id: 2, name: 'Bug' },
      status: { id: 2, name: 'Closed' },
      project: { name: 'My Project' },
      description: {
        format: 'markdown',
        raw: 'Description of WP2',
        html: '<p>Description of WP2</p>',
      },
      createdAt: '2021-03-26T10:42:14Z',
      updatedAt: '2021-03-26T10:42:14Z',
      dueDate: '2021-03-26T10:42:14Z',
      startDate: '2021-03-26T10:42:14Z',
    },
  ];

  type WindowWithOpenProject = Omit<Window, 'OpenProject'> & {
    OpenProject?:{
      environment:string;
    };
  };

  beforeEach(() => {
    (window as WindowWithOpenProject).OpenProject = { environment: 'test' };
  });

  afterEach(() => {
    delete (window as WindowWithOpenProject).OpenProject;
    vi.restoreAllMocks();
  });

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [OpAutocompleterComponent],
      schemas: [NO_ERRORS_SCHEMA],
      imports: [NgSelectModule],
      providers: [States, provideHttpClient(withXhr(), withInterceptorsFromDi()), provideHttpClientTesting()],
    }).compileComponents();

    fixture = TestBed.createComponent(OpAutocompleterComponent);
    getOptionsFnSpy = vi.fn().mockImplementation((searchTerm:string) => {
      return of(workPackagesStub).pipe(map((wps) => wps.filter((wp) => searchTerm !== '' && wp.subject.includes(searchTerm))));
    });

    fixture.componentInstance.resource = 'work_packages';
    fixture.componentInstance.filters = [];
    fixture.componentInstance.searchKey = 'typeahead';
    fixture.componentInstance.appendTo = 'body';
    fixture.componentInstance.multiple = false;
    fixture.componentInstance.closeOnSelect = true;
    fixture.componentInstance.virtualScroll = true;
    fixture.componentInstance.classes = 'wp-relations-autocomplete';
    fixture.componentInstance.getOptionsFn = getOptionsFnSpy;
    fixture.componentInstance.debounceTimeMs = 0;
  });

  it('should load the ng-select correctly', () => {
    vi.useFakeTimers();
    try {
      fixture.detectChanges();
      vi.advanceTimersByTime(0);

      const autocompleter = document.querySelector('.ng-select-container');

      expect(document.contains(autocompleter)).toBeTruthy();
    }
    finally {
      vi.useRealTimers();
    }
  });

  describe('without debounce', () => {
    it('should load items', () => {
      vi.useFakeTimers();
      try {
        fixture.detectChanges();
        vi.advanceTimersByTime(1000);
        fixture.detectChanges();
        const select = fixture.componentInstance.ngSelectInstance;

        expect(select.isOpen()).toBe(false);
        select.open();
        select.focus();

        expect(select.isOpen()).toBe(true);

        expect(select.itemsList.items.length).toEqual(0);

        const inputDebugElement = fixture.debugElement.query(By.css('input[role=combobox]'));
        const inputElement = inputDebugElement.nativeElement as HTMLInputElement;

        fixture.detectChanges();
        vi.advanceTimersByTime(0);

        expect(getOptionsFnSpy).toHaveBeenCalledWith('');

        inputElement.value = 'Wor';
        inputElement.dispatchEvent(new Event('input'));
        fixture.detectChanges();
        vi.advanceTimersByTime(0);

        expect(getOptionsFnSpy).toHaveBeenCalledWith('Wor');

        fixture.detectChanges();

        expect(select.itemsList.items.length).toEqual(2);

        inputElement.value = 'package 2';
        inputElement.dispatchEvent(new Event('input'));
        fixture.detectChanges();
        vi.advanceTimersByTime(0);

        expect(getOptionsFnSpy).toHaveBeenCalledWith('package 2');

        fixture.detectChanges();

        expect(select.itemsList.items.length).toEqual(1);
      }
      finally {
        vi.useRealTimers();
      }
    });
  });

  describe('work package option rendering', () => {
    it('should display formattedId in dropdown options', () => {
      vi.useFakeTimers();
      try {
        fixture.detectChanges();
        vi.advanceTimersByTime(1000);
        fixture.detectChanges();
        const select = fixture.componentInstance.ngSelectInstance;

        select.open();
        select.focus();

        const inputDebugElement = fixture.debugElement.query(By.css('input[role=combobox]'));
        const inputElement = inputDebugElement.nativeElement as HTMLInputElement;

        inputElement.value = 'Wor';
        inputElement.dispatchEvent(new Event('input'));
        fixture.detectChanges();
        vi.advanceTimersByTime(0);
        fixture.detectChanges();

        const wpIdElements = document.querySelectorAll('.op-autocompleter--wp-id');

        expect(wpIdElements.length).toBeGreaterThanOrEqual(1);
        // Verify at least one rendered option displays formattedId
        const renderedIds = Array.from(wpIdElements).map(el => el.textContent?.trim());

        expect(renderedIds).toContain('#1');
      }
      finally {
        vi.useRealTimers();
      }
    });

    it('should display classic formattedId in selected value label', () => {
      silenceDestroyedOutputWarning();
      vi.useFakeTimers();
      try {
        fixture.detectChanges();
        vi.advanceTimersByTime(1000);
        fixture.detectChanges();
        const select = fixture.componentInstance.ngSelectInstance;

        select.open();
        select.focus();

        const inputDebugElement = fixture.debugElement.query(By.css('input[role=combobox]'));
        const inputElement = inputDebugElement.nativeElement as HTMLInputElement;

        inputElement.value = 'Wor';
        inputElement.dispatchEvent(new Event('input'));
        fixture.detectChanges();
        vi.advanceTimersByTime(0);
        fixture.detectChanges();

        // Select the first item (classic mode: #1)
        select.select(select.itemsList.items[0]);
        fixture.detectChanges();

        const labelElement = document.querySelector('.ng-value-label');

        expect(labelElement).toBeTruthy();
        expect(labelElement!.textContent).toContain('#1');
        expect(labelElement!.textContent).toContain('Workpackage 1');
      }
      finally {
        vi.useRealTimers();
      }
    });

    it('should display semantic formattedId in selected value label', () => {
      silenceDestroyedOutputWarning();
      vi.useFakeTimers();
      try {
        fixture.detectChanges();
        vi.advanceTimersByTime(1000);
        fixture.detectChanges();
        const select = fixture.componentInstance.ngSelectInstance;

        select.open();
        select.focus();

        const inputDebugElement = fixture.debugElement.query(By.css('input[role=combobox]'));
        const inputElement = inputDebugElement.nativeElement as HTMLInputElement;

        inputElement.value = 'package 2';
        inputElement.dispatchEvent(new Event('input'));
        fixture.detectChanges();
        vi.advanceTimersByTime(0);
        fixture.detectChanges();

        // Select the semantic mode item (PROJ-2)
        select.select(select.itemsList.items[0]);
        fixture.detectChanges();

        const labelElement = document.querySelector('.ng-value-label');

        expect(labelElement).toBeTruthy();
        expect(labelElement!.textContent).toContain('PROJ-2');
        expect(labelElement!.textContent).not.toContain('#PROJ-2');
        expect(labelElement!.textContent).toContain('Workpackage 2');
      }
      finally {
        vi.useRealTimers();
      }
    });
  });

  describe('with debounce', () => {
    beforeEach(() => {
      fixture.componentInstance.debounceTimeMs = 50;
    });

    it('should load items with debounce', async () => {
      fixture.detectChanges();

      // Wait for ngAfterViewInit's internal setTimeout(25ms) and debounce to fire.
      await new Promise(resolve => setTimeout(resolve, 100));
      fixture.detectChanges();
      const select = fixture.componentInstance.ngSelectInstance;

      expect(select.isOpen()).toBe(false);
      select.open();
      select.focus();

      expect(select.isOpen()).toBe(true);

      expect(select.itemsList.items.length).toEqual(0);

      const inputDebugElement = fixture.debugElement.query(By.css('input[role=combobox]'));
      const inputElement = inputDebugElement.nativeElement as HTMLInputElement;

      fixture.detectChanges();

      // Wait for the initial '' search to fire via debounce.
      await new Promise(resolve => setTimeout(resolve, 100));

      expect(getOptionsFnSpy).toHaveBeenCalledWith('');
      getOptionsFnSpy.mockClear();

      inputElement.value = 'Wor';
      inputElement.dispatchEvent(new Event('input'));
      fixture.detectChanges();

      expect(getOptionsFnSpy).not.toHaveBeenCalled();

      // Wait for debounce (debounceTimeMs=50, but 0 in test env).
      await new Promise(resolve => setTimeout(resolve, 100));

      expect(getOptionsFnSpy).toHaveBeenCalledWith('Wor');
    });
  });
});

// NG0953 ("Unexpected emit for destroyed OutputRef") is emitted when ng-select
// emits on an OutputRef during fixture teardown under fake timers. It is a real
// lifecycle smell, not pure noise — silencing it here is a pragmatic stopgap so
// these specs stay readable, not a fix. The proper fix is to stop the
// emit-after-destroy in the component teardown path; until then this is
// scoped to the two affected specs and passes every other warning through so it
// does not hide unrelated regressions. Do not promote this to a global filter.
function silenceDestroyedOutputWarning():void {
  const originalWarn = console.warn.bind(console);

  vi.spyOn(console, 'warn').mockImplementation((message?:unknown, ...args:unknown[]) => {
    if (typeof message === 'string' && message.startsWith('NG0953: Unexpected emit for destroyed `OutputRef`')) {
      return;
    }

    originalWarn(message, ...args);
  });
}

describe('derived autocompleter', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [TestAutocompleterComponent],
      providers: [States, provideHttpClient(withXhr(), withInterceptorsFromDi()), provideHttpClientTesting()],
    }).compileComponents();
  });

  it('provides shared autocompleter dependencies to subclasses', () => {
    const fixture = TestBed.createComponent(TestAutocompleterComponent);

    expect(fixture.componentInstance.opAutocompleterService).toBeDefined();
  });
});
