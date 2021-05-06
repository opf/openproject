import { HttpClientModule } from '@angular/common/http';
import { Injector, Input } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { OpenProjectDirectFileUploadService } from 'core-app/components/api/op-file-upload/op-direct-file-upload.service';
import { OpenProjectFileUploadService } from 'core-app/components/api/op-file-upload/op-file-upload.service';
import { States } from 'core-app/components/states.service';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { HalResourceNotificationService } from 'core-app/modules/hal/services/hal-resource-notification.service';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { TabComponent } from '../../components/wp-tab-wrapper/tab';

import { WorkPackageTabsService } from './wp-tabs.service';
import { StateService } from "@uirouter/angular";
import { WorkPackageRelationsService } from "core-components/wp-relations/wp-relations.service";

describe('WpTabsService', () => {
  let service:WorkPackageTabsService;
  let workPackage:any = { id: 1234 };
  let injector:Injector;
  let halResourceService:HalResourceService;

  class TestComponent implements TabComponent {
    @Input() public workPackage:WorkPackageResource;
  }

  const displayableTab = {
    component: TestComponent,
    name: 'Displayable TestTab',
    identifier: 'displayable-test-tab',
    displayable: () => true,
  };

  const notDisplayableTab = {
    component: TestComponent,
    name: 'NotDisplayable TestTab',
    identifier: 'not-displayable-test-tab',
    displayable: () => false,
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        HttpClientModule,
      ],
      providers: [
        { provide: StateService, useValue: { includes: () => false } }
      ]
    });
    service = TestBed.inject(WorkPackageTabsService);
    (service as any).registeredTabs = [];
    service.register(displayableTab, notDisplayableTab);

    injector = TestBed.inject(Injector);
  });

  describe('displayableTabs()', () => {
    it('returns just the displayable tab', () => {
      expect(service.getDisplayableTabs(workPackage)).toEqual([displayableTab]);
    });
  });

  describe('getTab()', () => {
    it('returns the displayable tab whith the correct identifier', () => {
      expect(service.getTab('displayable-test-tab', workPackage)?.identifier).toEqual('displayable-test-tab');
      expect(service.getTab('non-existing-tab', workPackage)).toEqual(undefined);
      expect(service.getTab('non-displayable-test-tab', workPackage)).toEqual(undefined);
    });
  });
});
