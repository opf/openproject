import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ChangeDetectorRef, Component, DebugElement, Input, ChangeDetectionStrategy } from '@angular/core';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { GitActionsMenuDirective } from 'core-app/features/plugins/linked/openproject-github_integration/git-actions-menu/git-actions-menu.directive';
import { TabPrsComponent } from 'core-app/features/plugins/linked/openproject-github_integration/tab-prs/tab-prs.component';
import { GithubPullRequestResourceService } from '../state/github-pull-request.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { of } from 'rxjs';
import { PullRequestComponent } from 'core-app/features/plugins/linked/openproject-github_integration/pull-request/pull-request.component';
import { By } from '@angular/platform-browser';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IGithubPullRequest } from '../state/github-pull-request.model';
import { PullRequestStateComponent } from '../pull-request/pull-request-state.component';

@Component({
  selector: 'op-date-time',
  template: '<p>OpDateTimeComponent </p>',
  changeDetection: ChangeDetectionStrategy.Eager,
  standalone: false,
})
class OpDateTimeComponent {
  @Input()
  dateTimeValue:any;
}

describe('TabPrsComponent', () => {
  let component:TabPrsComponent;
  let fixture:ComponentFixture<TabPrsComponent>;
  let element:DebugElement;
  let githubPullRequestResourceServiceSpy:{ ofWorkPackage:ReturnType<typeof vi.fn> };
  let changeDetectorRef:ChangeDetectorRef & { detectChanges:ReturnType<typeof vi.fn> };
  const I18nServiceStub = {
    t: function (key:string) {
      return 'test translation';
    }
  };
  const ApiV3Stub = {
    work_packages: {
      id: () => ({ github_pull_requests: 'prpath' })
    }
  };

  const pullRequests:IGithubPullRequest[] = [
    {
      id: 1,
      title: 'title 1',
      githubUpdatedAt: 'githubUser 1 githubUpdatedAt',
      htmlUrl: 'githubUser 1 htmlUrl',
      repository: 'githubUser 1 repository',
      repositoryHtmlUrl: 'githubUser 2 repositoryHtmlUrl',
      number: 1,
      _links: {
        githubUser: {
          href: 'githubUser 1 api url',
          title: 'gitHubUser 1 title'
        },
        self: {
          href: 'this href',
          title: 'this title'
        }
      },
      _embedded: {
        githubUser: {
          avatarUrl: 'githubUser 1 avatarUrl',
          htmlUrl: 'githubUser 1 htmlUrl',
          login: 'githubUser 1 login',
        },
        checkRuns: [
          {
            appOwnerAvatarUrl: 'githubUser 1 checkRuns appOwnerAvatarUrl',
            completedAt: 'githubUser 1 checkRuns completedAt',
            conclusion: 'githubUser 1 checkRuns conclusion',
            detailsUrl: 'githubUser 1 checkRuns detailsurl',
            htmlUrl: 'githubUser 1 checkRuns htmlUrl',
            name: 'githubUser 1 checkRuns name',
            outputSummary: 'githubUser 1 checkRuns outputSummary',
            outputTitle: 'githubUser 1 checkRuns outputTitle',
            startedAt: 'githubUser 1 checkRuns startedAt',
            status: 'githubUser 1 checkRuns status',
          }
        ],
      }
    },
    {
      id: 2,
      title: 'title 2',
      githubUpdatedAt: 'githubUser 2 githubUpdatedAt',
      htmlUrl: 'githubUser 2 htmlUrl',
      repository: 'githubUser 2 repository',
      repositoryHtmlUrl: 'githubUser 2 repositoryHtmlUrl',
      number: 2,
      _links: {
        githubUser: {
          href: 'githubUser 2 api url',
          title: 'gitHubUser 2 title'
        },
        self: {
          href: 'this href',
          title: 'this title'
        }
      },
      _embedded: {
        githubUser: {
          avatarUrl: 'githubUser 2 avatarUrl',
          htmlUrl: 'githubUser 2 htmlUrl',
          login: 'githubUser 2 login',
        },
        checkRuns: [
          {
            appOwnerAvatarUrl: 'githubUser 2 checkRuns appOwnerAvatarUrl',
            completedAt: 'githubUser 2 checkRuns completedAt',
            conclusion: 'githubUser 2 checkRuns conclusion',
            detailsUrl: 'githubUser 2 checkRuns detailsurl',
            htmlUrl: 'githubUser 2 checkRuns htmlUrl',
            name: 'githubUser 2 checkRuns name',
            outputSummary: 'githubUser 2 checkRuns outputSummary',
            outputTitle: 'githubUser 2 checkRuns outputTitle',
            startedAt: 'githubUser 2 checkRuns startedAt',
            status: 'githubUser 2 checkRuns status',
          }
        ],
      }
    }
  ];

  beforeEach(async () => {
    const changeDetectorSpy = {
      detectChanges: vi.fn().mockName('ChangeDetectorRef.detectChanges')
    };
    githubPullRequestResourceServiceSpy = {
      ofWorkPackage: vi.fn().mockName('GithubPullRequestResourceService.ofWorkPackage')
    };
    // @ts-ignore
    githubPullRequestResourceServiceSpy.ofWorkPackage.mockReturnValue(of(pullRequests));

    await TestBed
      .configureTestingModule({
      declarations: [
        TabPrsComponent,
        OpIconComponent,
        GitActionsMenuDirective,
        PullRequestComponent,
        PullRequestStateComponent,
        OpDateTimeComponent,
      ],
      providers: [
        { provide: I18nService, useValue: I18nServiceStub },
        { provide: ApiV3Service, useValue: ApiV3Stub },
        { provide: ChangeDetectorRef, useValue: changeDetectorSpy },
        { provide: GithubPullRequestResourceService, useValue: githubPullRequestResourceServiceSpy },
      ],
    })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(TabPrsComponent);
    component = fixture.componentInstance;
    element = fixture.debugElement;
    changeDetectorRef = fixture.debugElement.injector.get(ChangeDetectorRef) as ChangeDetectorRef & { detectChanges:ReturnType<typeof vi.fn> };
    // @ts-ignore
    component.workPackage = { id: 'testId' };

    changeDetectorRef.markForCheck();
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should display a PullRequestComponent per pull request', () => {
    const pullRequests = fixture.debugElement.queryAll(By.css('op-github-pull-request'));

    expect(pullRequests.length).toBe(2);
  });

  it('should display a message when there are no pull requests', () => {
    component.pullRequests$ = of([]);
    changeDetectorRef.markForCheck();
    fixture.detectChanges();

    const pullRequests = fixture.debugElement.queryAll(By.css('op-github-pull-request'));
    const textMessage = fixture.debugElement.queryAll(By.css('p'));

    expect(pullRequests.length).toBe(0);
    expect(textMessage).toBeTruthy();
  });
});
