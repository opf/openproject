import {
  ComponentFixture,
  TestBed,
} from '@angular/core/testing';
import { DebugElement }  from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import { GitHubTabComponent } from "core-app/modules/plugins/linked/openproject-github_integration/github-tab/github-tab.component";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { TabPrsComponent } from "core-app/modules/plugins/linked/openproject-github_integration/tab-prs/tab-prs.component";
import { TabHeaderComponent } from "core-app/modules/plugins/linked/openproject-github_integration/tab-header/tab-header.component";
import { By } from "@angular/platform-browser";


describe('GitHubTabComponent.', () => {
  let component:GitHubTabComponent;
  let fixture:ComponentFixture<GitHubTabComponent>;
  let element:DebugElement;
  const apiV3Base = 'http://www.openproject.com/api/v3/';
  const IPathHelperServiceStub = { api:{ v3: { apiV3Base }}};
  const I18nServiceStub = {
    t: function(key:string) {
      return 'test translation';
    }
  }

  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
        declarations: [
          TabPrsComponent,
          TabHeaderComponent,
        ],
        providers: [
          { provide: I18nService, useValue: I18nServiceStub },
          { provide: PathHelperService, useValue: IPathHelperServiceStub },
        ],
      })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(GitHubTabComponent);
    component = fixture.componentInstance;
    element = fixture.debugElement;

    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should render header and pull requests components', () => {
    const tabHeader = fixture.debugElement.query(By.css('tab-header'));
    const tabPrs = fixture.debugElement.query(By.css('tab-prs'));

    expect(tabHeader).toBeTruthy();
    expect(tabPrs).toBeTruthy();
  });
});
