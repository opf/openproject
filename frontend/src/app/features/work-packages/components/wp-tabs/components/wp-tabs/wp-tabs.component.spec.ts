import { Component, Input, NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { StateService, UIRouterGlobals } from '@uirouter/core';
import { ScrollableTabsComponent } from 'core-app/shared/components/tabs/scrollable-tabs/scrollable-tabs.component';
import { WorkPackageTabsService } from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { WpTabsComponent } from './wp-tabs.component';
import { TabComponent } from '../wp-tab-wrapper/tab';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

describe('WpTabsComponent', () => {
  @Component({
    template: '',
    standalone: false,
  })
  class TestComponent implements TabComponent {
    @Input()
    public workPackage:WorkPackageResource;
  }

  const displayableTab = {
    component: TestComponent,
    name: 'Displayable TestTab',
    id: 'displayable-test-tab',
    displayable: () => true,
  };

  const notDisplayableTab = {
    component: TestComponent,
    name: 'NotDisplayable TestTab',
    id: 'not-displayable-test-tab',
    displayable: () => false,
  };

  let component:WpTabsComponent;
  let service:WorkPackageTabsService;
  let fixture:ComponentFixture<WpTabsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [WpTabsComponent, ScrollableTabsComponent],
      providers: [
        { provide: StateService, useValue: { includes: () => false } },
        { provide: UIRouterGlobals, useValue: {} },
        { provide: KeepTabService, useValue: {} },
        { provide: CurrentProjectService, useValue: {} },
        { provide: PathHelperService, useValue: {} },
        WorkPackageTabsService,
      ],
      schemas: [NO_ERRORS_SCHEMA]
    })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(WpTabsComponent);
    service = TestBed.inject(WorkPackageTabsService);
    (service as any).registeredTabs = [];
    service.register(displayableTab, notDisplayableTab);

    component = fixture.componentInstance;
    component.workPackage = {} as WorkPackageResource;
    fixture.detectChanges();
  });

  it('displays the visible tab', () => {
    const tabLink:HTMLElement = fixture.debugElement.query(By.css('[data-qa-tab-id="displayable-test-tab"]')).nativeElement;

    expect(tabLink.textContent).toContain('Displayable TestTab');
  });
});
