import { HttpClientModule } from '@angular/common/http';
import { Injector } from '@angular/core';
import { Input } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { OpenProjectDirectFileUploadService } from 'core-app/components/api/op-file-upload/op-direct-file-upload.service';
import { OpenProjectFileUploadService } from 'core-app/components/api/op-file-upload/op-file-upload.service';
import { States } from 'core-app/components/states.service';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { HalResourceNotificationService } from 'core-app/modules/hal/services/hal-resource-notification.service';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { HookService } from 'core-app/modules/plugins/hook-service';
import { Tab, TabComponent } from '../../components/wp-tab-wrapper/tab';

import { WpTabsService } from './wp-tabs.service';

describe('WpTabsService', () => {
  let service: WpTabsService;
  let workPackage:WorkPackageResource;
  let injector:Injector;
  let halResourceService:HalResourceService;

  let source = {
    _type: 'WorkPackage',
    id: '1234',
    _links: {}
  };

  class TestComponent implements TabComponent {
    @Input() public workPackage:WorkPackageResource;
  }

  const displayableTab = new Tab(TestComponent, 'Displayable TestTab', 'displayable-test-tab', (_) => true)
  const nonDisplayableTab = new Tab(TestComponent, 'NotDisplayable TestTab', 'non-displayable-test-tab', (_) => false)

  const HookServiceStub = {
    getWorkPackageTabs: () => [displayableTab, nonDisplayableTab]
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        HttpClientModule
      ],
      providers: [
        { provide: HookService, useValue: HookServiceStub },
        OpenProjectFileUploadService,
        OpenProjectDirectFileUploadService,
        HalResourceService,
        HalResourceNotificationService,
        States
      ]
    });
    service = TestBed.inject(WpTabsService);

    injector = TestBed.inject(Injector);
    halResourceService = injector.get(HalResourceService);
    workPackage = halResourceService.createHalResourceOfClass(WorkPackageResource, source, true);
  });

  describe('displayableTabs()', () =>{
    it('returns just the displayable tab', () => {
      expect(service.getDisplayableTabs(workPackage)).toEqual([displayableTab]);
    });
  });

  describe('getTab()', () =>{
    it('returns the displayable tab whith the correct identifier', () => {
      expect(service.getTab('displayable-test-tab', workPackage)).toEqual(displayableTab);
      expect(service.getTab('non-existing-tab', workPackage)).toEqual(undefined);
      expect(service.getTab('non-displayable-test-tab', workPackage)).toEqual(undefined);
    });
  });
});
