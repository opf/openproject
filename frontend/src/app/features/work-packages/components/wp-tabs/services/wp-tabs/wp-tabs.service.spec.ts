import { HttpClientModule } from '@angular/common/http';
import { Injector, Input } from '@angular/core';

import { TestBed } from '@angular/core/testing';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { StateService } from '@uirouter/angular';
import { WorkPackageTabsService } from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { TabComponent } from '../../components/wp-tab-wrapper/tab';

describe('WpTabsService', () => {
  let service:WorkPackageTabsService;
  const workPackage:any = { id: 1234 };
  let injector:Injector;
  let halResourceService:HalResourceService;

  class TestComponent implements TabComponent {
    @Input() public workPackage:WorkPackageResource;
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

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        HttpClientModule,
      ],
      providers: [
        { provide: StateService, useValue: { includes: () => false } },
      ],
    });
    service = TestBed.inject(WorkPackageTabsService);
    (service as any).registeredTabs = [];
    service.register(displayableTab, notDisplayableTab);

    injector = TestBed.inject(Injector);
  });

  describe('displayableTabs()', () => {
    it('returns just the displayable tab', () => {
      expect(service.getDisplayableTabs(workPackage)[0].id).toEqual(displayableTab.id);
    });
  });

  describe('getTab()', () => {
    it('returns the displayable tab whith the correct identifier', () => {
      expect(service.getTab('displayable-test-tab', workPackage)?.id).toEqual('displayable-test-tab');
      expect(service.getTab('non-existing-tab', workPackage)).toEqual(undefined);
      expect(service.getTab('non-displayable-test-tab', workPackage)).toEqual(undefined);
    });
  });
});
