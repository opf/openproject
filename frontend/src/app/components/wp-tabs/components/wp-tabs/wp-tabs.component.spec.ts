import { Input } from '@angular/core';
import { ComponentFixture, fakeAsync, TestBed, tick, waitForAsync } from '@angular/core/testing';
import { By } from '@angular/platform-browser';

import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';

import { TabComponent } from '../wp-tab-wrapper/tab';
import { WpTabsComponent } from './wp-tabs.component';
import { WorkPackageTabsService } from "core-components/wp-tabs/services/wp-tabs/wp-tabs.service";
import { StateService } from "@uirouter/angular";
import { UIRouterGlobals } from "@uirouter/core";
import { KeepTabService } from "core-components/wp-single-view-tabs/keep-tab/keep-tab.service";
import { ScrollableTabsComponent } from "core-app/modules/common/tabs/scrollable-tabs/scrollable-tabs.component";

describe('WpTabsComponent', () => {
  class TestComponent implements TabComponent {
    @Input() public workPackage:WorkPackageResource;
  }

  const displayableTab = {
    component: TestComponent,
    name: 'Displayable TestTab',
    id: 'displayable-test-tab',
    displayable: () => true
  };

  const notDisplayableTab = {
    component: TestComponent,
    name: 'NotDisplayable TestTab',
    id: 'not-displayable-test-tab',
    displayable: () => false
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
        WorkPackageTabsService,
      ],
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

  it('displays the visible tab', fakeAsync(() => {
    const tabLink:HTMLElement = fixture.debugElement.query(By.css('[data-qa-tab-id="displayable-test-tab"]')).nativeElement;
    expect(tabLink.innerText).toContain('Displayable TestTab');
  }));
});
