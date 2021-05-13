import { HttpClientModule } from '@angular/common/http';
import { Injector } from '@angular/core';
import {Input} from '@angular/core';
import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { OpenProjectDirectFileUploadService } from 'core-app/core/file-upload/op-direct-file-upload.service';
import { OpenProjectFileUploadService } from 'core-app/core/file-upload/op-file-upload.service';
import { States } from 'core-app/components/states.service';

import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { HalResourceNotificationService } from 'core-app/modules/hal/services/hal-resource-notification.service';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { HookService } from 'core-app/modules/plugins/hook-service';

import { Tab, TabComponent } from '../wp-tab-wrapper/tab';
import { WpTabsComponent } from './wp-tabs.component';

describe('WpTabsComponent', () => {
  class TestComponent implements TabComponent {
    @Input() public workPackage:WorkPackageResource;
  }

  const displayableTab = new Tab(TestComponent, 'Displayable TestTab', 'displayable-test-tab', (_) => true)
  const notDisplayableTab = new Tab(TestComponent, 'NotDisplayable TestTab', 'not-displayable-test-tab', (_) => false)

  const HookServiceStub = {
    getWorkPackageTabs: () => [displayableTab, notDisplayableTab]
  };

  let component: WpTabsComponent;
  let fixture: ComponentFixture<WpTabsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ WpTabsComponent ],
      providers: [
        { provide: HookService, useValue: HookServiceStub }
      ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(WpTabsComponent);
    component = fixture.componentInstance;
    component.workPackage = {} as WorkPackageResource;
    fixture.detectChanges();
  });

  it('displays the visible tab', waitForAsync(() => {
    fixture.whenStable().then(() => {
      const tabLink:HTMLElement = fixture.debugElement.query(By.css('li a')).nativeElement;
      expect(tabLink.innerText).toContain('Displayable TestTab');
    });
  }));
});
