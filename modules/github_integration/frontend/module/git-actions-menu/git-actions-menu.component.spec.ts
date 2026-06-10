import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DebugElement } from '@angular/core';
import { GitHubActionsMenuComponent } from './git-actions-menu.component';
import { GitActionsService } from '../git-actions/git-actions.service';
import { By } from '@angular/platform-browser';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpContextMenuLocalsToken } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

describe('GitHubActionsMenuComponent', () => {
  let component:GitHubActionsMenuComponent;
  let fixture:ComponentFixture<GitHubActionsMenuComponent>;
  let element:DebugElement;
  let gitActionsService:{ gitCommand:ReturnType<typeof vi.fn>; commitMessage:ReturnType<typeof vi.fn>; commitMessageDisplayText:ReturnType<typeof vi.fn>; branchName:ReturnType<typeof vi.fn> };
  const I18nServiceStub = {
    t: function (key:string) {
      return 'test translation';
    }
  };
  const localsStub = {
    workPackage: 1,
    items: [
      {
        hidden: false,
        disabled: false,
        href: 'http://www.google.com',
        linkText: 'linkText',
      }
    ]
  };

  beforeEach(async () => {
    const gitActionsServiceSpy = {
      gitCommand: vi.fn().mockName('GitActionsService.gitCommand'),
      commitMessage: vi.fn().mockName('GitActionsService.commitMessage'),
      branchName: vi.fn().mockName('GitActionsService.branchName')
    };

    await TestBed
      .configureTestingModule({
        declarations: [
          GitHubActionsMenuComponent,
          OpIconComponent,
        ],
        providers: [
          { provide: I18nService, useValue: I18nServiceStub },
          { provide: OpContextMenuLocalsToken, useValue: localsStub },
          { provide: GitActionsService, useValue: gitActionsServiceSpy },
        ],
      })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(GitHubActionsMenuComponent);
    component = fixture.componentInstance;
    element = fixture.debugElement;
    gitActionsService = fixture.debugElement.injector.get(GitActionsService) as unknown as typeof gitActionsService;

    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should generate the branch name on copy button click', () => {
    const copyButton = fixture.debugElement.query(By.css('.copy-button')).nativeElement;

    gitActionsService.branchName.mockReturnValue('test branch');
    copyButton.click();

    fixture.detectChanges();

    expect(gitActionsService.branchName).toHaveBeenCalled();
  });
});
