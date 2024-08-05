import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DebugElement } from '@angular/core';
import { GitActionsMenuComponent } from "./git-actions-menu.component";
import { GitActionsService } from "../git-actions/git-actions.service";
import { By } from "@angular/platform-browser";
import { OpIconComponent } from "core-app/shared/components/icon/icon.component";
import { I18nService } from "core-app/core/i18n/i18n.service";
import { OpContextMenuLocalsToken } from "core-app/shared/components/op-context-menu/op-context-menu.types";


describe('GitActionsMenuComponent', () => {
  let component:GitActionsMenuComponent;
  let fixture:ComponentFixture<GitActionsMenuComponent>;
  let element:DebugElement;
  let gitActionsService:jasmine.SpyObj<GitActionsService>;
  const I18nServiceStub = {
    t: function(key:string) {
      return 'test translation';
    }
  }
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
  }

  beforeEach(async () => {
    const gitActionsServiceSpy = jasmine.createSpyObj('GitActionsService', ['gitCommand', 'commitMessage', 'commitMessageDisplayText', 'branchName']);

    await TestBed
      .configureTestingModule({
        declarations: [
          GitActionsMenuComponent,
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
    fixture = TestBed.createComponent(GitActionsMenuComponent);
    component = fixture.componentInstance;
    element = fixture.debugElement;
    gitActionsService = fixture.debugElement.injector.get(GitActionsService) as jasmine.SpyObj<GitActionsService>;

    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should generate the branch name on copy button click', () => {
    const copyButton = fixture.debugElement.query(By.css('.copy-button')).nativeElement;

    gitActionsService.branchName.and.returnValue('test branch');
    copyButton.click();

    fixture.detectChanges();

    expect(gitActionsService.branchName).toHaveBeenCalled();
  });
});
