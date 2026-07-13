import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Component, DebugElement, Input, ChangeDetectionStrategy } from '@angular/core';
import { GitHubTabComponent } from 'core-app/features/plugins/linked/openproject-github_integration/github-tab/github-tab.component';
import { By } from '@angular/platform-browser';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

@Component({
  selector: 'tab-header',
  template: '',
  changeDetection: ChangeDetectionStrategy.Eager,
  standalone: false,
})
class TabHeaderStubComponent {
  @Input() workPackage:WorkPackageResource;
}

@Component({
  selector: 'op-tab-prs',
  template: '',
  changeDetection: ChangeDetectionStrategy.Eager,
  standalone: false,
})
class TabPrsStubComponent {
  @Input() workPackage:WorkPackageResource;
}

describe('GitHubTabComponent.', () => {
  let component:GitHubTabComponent;
  let fixture:ComponentFixture<GitHubTabComponent>;
  let element:DebugElement;
  const workPackage = { id: 'testId' } as WorkPackageResource;
  const apiV3Base = 'http://www.openproject.com/api/v3/';
  const IPathHelperServiceStub = { api: { v3: { apiV3Base } } };
  const I18nServiceStub = {
    t: function (key:string) {
      return 'test translation';
    }
  };

  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
      declarations: [
        GitHubTabComponent,
        TabHeaderStubComponent,
        TabPrsStubComponent,
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
    component.workPackage = workPackage;

    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should render header and pull requests components', () => {
    const tabHeader = fixture.debugElement.query(By.css('tab-header'));
    const tabPrs = fixture.debugElement.query(By.css('op-tab-prs'));

    expect(tabHeader).toBeTruthy();
    expect(tabPrs).toBeTruthy();
  });

  it('should pass the work package to the child components', () => {
    const tabHeader = fixture.debugElement.query(By.directive(TabHeaderStubComponent));
    const tabPrs = fixture.debugElement.query(By.directive(TabPrsStubComponent));

    expect(tabHeader.componentInstance.workPackage).toBe(workPackage);
    expect(tabPrs.componentInstance.workPackage).toBe(workPackage);
  });
});
