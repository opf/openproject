//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { ReplaySubject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { IGithubPullRequest } from '../state/github-pull-request.model';
import { GithubPullRequestResourceService } from '../state/github-pull-request.service';
import { PullRequestMacroComponent } from './pull-request-macro.component';
import { PullRequestStateComponent } from './pull-request-state.component';

@Component({ selector: 'op-content-loader', template: '<ng-content />', standalone: false })
class ContentLoaderStubComponent {
  @Input() viewBox:string;
}

describe('PullRequestMacroComponent nullable producer', () => {
  let fixture:ComponentFixture<PullRequestMacroComponent>;
  let pullRequest$:ReplaySubject<IGithubPullRequest>;

  const pullRequest:IGithubPullRequest = {
    id: 3,
    htmlUrl: 'https://github.com/opf/openproject/pull/3',
    title: 'A real pull request',
    state: 'open',
    githubUpdatedAt: '2026-10-30T10:00:00Z',
    repository: 'opf/openproject',
    repositoryHtmlUrl: 'https://github.com/opf/openproject',
    _links: { self: { href: '/api/v3/github_pull_requests/3', title: 'A real pull request' }, githubUser: { href: '/api/v3/github_users/1', title: 'author' } },
    _embedded: {
      githubUser: { login: 'author', htmlUrl: 'https://github.com/author', avatarUrl: '/avatar' },
      checkRuns: [],
    },
  };

  beforeEach(async () => {
    pullRequest$ = new ReplaySubject<IGithubPullRequest>(1);
    await TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [PullRequestMacroComponent, PullRequestStateComponent, OpIconComponent, ContentLoaderStubComponent],
      providers: [
        { provide: GithubPullRequestResourceService, useValue: { requireSingle: () => pullRequest$ } },
        { provide: I18nService, useValue: { t: (_key:string, options?:{ pr_link?:string, repository_link?:string }) => options?.pr_link ? `${options.pr_link} ${options.repository_link}` : _key } },
      ],
    }).compileComponents();
    fixture = TestBed.createComponent(PullRequestMacroComponent);
    fixture.componentRef.setInput('pullRequestId', '3');
    fixture.componentRef.setInput('pullRequestState', 'opened');
    fixture.detectChanges();
  });

  it('shows the loading placeholder until a pull request arrives', () => {
    expect(fixture.debugElement.query(By.css('op-content-loader'))).not.toBeNull();
    expect(fixture.debugElement.query(By.css('.op-pull-request-macro'))).toBeNull();
  });

  it('renders the repository label without a link when its URL is absent', async () => {
    const resource = { ...pullRequest };
    Object.assign(resource, { repositoryHtmlUrl: undefined });
    pullRequest$.next(resource);
    await fixture.whenStable();
    const macro:HTMLElement = fixture.debugElement.query(By.css('.op-pull-request-macro')).nativeElement;
    const repository = Array.from(macro.querySelectorAll('a, span')).find(element => element.textContent === 'opf/openproject');
    expect(repository?.tagName).toBe('SPAN');
    expect(macro.querySelector('a')?.href).toBe(pullRequest.htmlUrl);
  });
});
