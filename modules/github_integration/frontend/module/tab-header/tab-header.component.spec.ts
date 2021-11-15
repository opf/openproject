import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DebugElement } from '@angular/core';
import { TabHeaderComponent } from "core-app/features/plugins/linked/openproject-github_integration/tab-header/tab-header.component";
import { By } from "@angular/platform-browser";
import { OpIconComponent } from "core-app/shared/components/icon/icon.component";
import { GitActionsMenuDirective } from "core-app/features/plugins/linked/openproject-github_integration/git-actions-menu/git-actions-menu.directive";
import { OPContextMenuService } from "core-app/shared/components/op-context-menu/op-context-menu.service";
import { I18nService } from "core-app/core/i18n/i18n.service";


describe('TabHeaderComponent', () => {
  let component:TabHeaderComponent;
  let fixture:ComponentFixture<TabHeaderComponent>;
  let element:DebugElement;
  const I18nServiceStub = {
    t: function(key:string) {
      return 'test translation';
    }
  }
  let oPContextMenuService:jasmine.SpyObj<OPContextMenuService>;
  // @ts-ignore
  window.Mousetrap = () => () => {};

  beforeEach(async () => {
    const oPContextMenuServiceSpy = jasmine.createSpyObj('OPContextMenuService', ['show']);

    await TestBed
      .configureTestingModule({
        declarations: [
          TabHeaderComponent,
          OpIconComponent,
          GitActionsMenuDirective,
        ],
        providers: [
          { provide: I18nService, useValue: I18nServiceStub },
          { provide: OPContextMenuService, useValue: oPContextMenuServiceSpy },
        ],
      })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(TabHeaderComponent);
    component = fixture.componentInstance;
    element = fixture.debugElement;
    oPContextMenuService = fixture.debugElement.injector.get(OPContextMenuService) as jasmine.SpyObj<OPContextMenuService>;

    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should render title and copy button', () => {
    const headerTitle = fixture.debugElement.query(By.css('h3')).nativeElement;
    const headerCopyButton = fixture.debugElement.query(By.css('button.github-git-copy[gitActionsCopyDropdown]')).nativeElement;

    expect(headerTitle.textContent.trim()).toBe('test translation');
    expect(headerCopyButton).toBeTruthy();
  });
});
