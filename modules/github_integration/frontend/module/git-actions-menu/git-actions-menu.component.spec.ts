import {
  ComponentFixture,
  TestBed,
} from '@angular/core/testing';
import { DebugElement }  from '@angular/core';
import { GitActionsMenuComponent } from "./git-actions-menu.component";
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import { OpContextMenuLocalsToken } from "core-app/components/op-context-menu/op-context-menu.types";
import { GitActionsService } from "../git-actions/git-actions.service";
import { OpIconComponent } from "core-app/modules/common/icon/icon.component";
import { By } from "@angular/platform-browser";


describe('GitActionsMenuComponent.', () => {
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
    const gitActionsServiceSpy = jasmine.createSpyObj('GitActionsService', ['gitCommand', 'commitMessage', 'branchName']);

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

  it('should select tab', () => {
    const tabToSelect = component.tabs[0];
    component.selectTab(tabToSelect);

    fixture.detectChanges();

    expect(component.selectedTab()).toBe(tabToSelect);
  });

  it('should select tab', () => {
    const tabToSelect = component.tabs[0];
    const copyButton = fixture.debugElement.query(By.css('button')).nativeElement;

    gitActionsService.branchName.and.returnValue('test branch');
    component.selectTab(tabToSelect);
    copyButton.click();

    fixture.detectChanges();

    expect(gitActionsService.branchName).toHaveBeenCalled();
  });
});
