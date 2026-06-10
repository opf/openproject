import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Component, DebugElement, Input } from '@angular/core';
import { By } from '@angular/platform-browser';
import { PullRequestComponent } from './pull-request.component';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { IGithubCheckRunResource, IGithubPullRequest, IGithubUserResource } from '../state/github-pull-request.model';
import { PullRequestStateComponent } from './pull-request-state.component';

@Component({
  selector: 'op-date-time',
  template: '',
  standalone: false,
})
class OpDateTimeComponent {
  @Input()
  dateTimeValue:any;
}

describe('PullRequestComponent', () => {
  let component:PullRequestComponent;
  let fixture:ComponentFixture<PullRequestComponent>;
  let element:DebugElement;
  const githubUser:IGithubUserResource = {
    avatarUrl: 'testavatarurl',
    htmlUrl: 'test htmlUrl',
    login: 'test login',
  };
  const checkRun:IGithubCheckRunResource = {
    appOwnerAvatarUrl: 'test appOwnerAvatarUrl',
    completedAt: 'test completedAt',
    conclusion: 'test conclusion',
    detailsUrl: 'testdetailsurl',
    htmlUrl: 'test htmlUrl',
    name: 'test name',
    outputSummary: 'test outputSummary',
    outputTitle: 'test outputTitle',
    startedAt: 'test startedAt',
    status: 'test status',
  };
  const pullRequestStub:IGithubPullRequest = {
    id: 3,
    additionsCount: 3,
    body: {
      format: '',
      raw: 'test raw',
      html: '<p>test</p>',
    },
    changedFilesCount: 3,
    commentsCount: 3,
    createdAt: 'test createdAt',
    deletionsCount: 3,
    draft: false,
    githubUpdatedAt: 'test githubUpdatedAt',
    htmlUrl: 'test htmlUrl',
    labels: ['test'],
    merged: false,
    mergedAt: '',
    number: 3,
    repository: 'test repository',
    repositoryHtmlUrl: 'test repositoryHtmlUrl',
    reviewCommentsCount: 3,
    state: 'open',
    title: 'test title',
    updatedAt: 'test updatedAt',
    _links: {
      githubUser: {
        href: 'test api url',
        title: 'test github user'
      },
      self: {
        href: 'this url',
        title: 'this title'
      }
    },
    _embedded: {
      githubUser,
      mergedBy: githubUser,
      checkRuns: [checkRun],
    }
  };

  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
      declarations: [
        PullRequestComponent,
        OpDateTimeComponent,
        OpIconComponent,
        PullRequestStateComponent,
      ],
    })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(PullRequestComponent);
    component = fixture.componentInstance;
    element = fixture.debugElement;
    // @ts-ignore
    component.pullRequest = pullRequestStub;

    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should render pull request data', () => {
    const titleElement = fixture.debugElement.query(By.css('.op-pull-request--title')).nativeElement;
    const avatarElement = fixture.debugElement.query(By.css('.op-avatar')).nativeElement;
    const userElement = fixture.debugElement.query(By.css('.op-principal')).nativeElement;
    const detailsElement = fixture.debugElement.query(By.css('.op-pull-request--link')).nativeElement;
    const checkRuns = fixture.debugElement.queryAll(By.css('.op-pr-check'));
    const checkRunElement = checkRuns[0].nativeElement;
    const checkRunLinkElement = checkRuns[0].query(By.css('a')).nativeElement;

    expect(titleElement.textContent).toContain(pullRequestStub.title);
    expect(avatarElement.src).toContain(pullRequestStub._embedded.githubUser.avatarUrl);
    expect(userElement.textContent).toContain(pullRequestStub._embedded.githubUser.login);
    expect(detailsElement.textContent).toContain(`${pullRequestStub.repository}#${pullRequestStub.number}`);
    expect(checkRuns.length).toBe(1);
    expect(checkRunElement.textContent).toContain(pullRequestStub._embedded.checkRuns[0].name);
    expect(checkRunLinkElement.href).toContain(pullRequestStub._embedded.checkRuns[0].detailsUrl);
  });
});
