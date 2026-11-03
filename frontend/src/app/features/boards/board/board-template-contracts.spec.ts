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

import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { Subject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { VersionResource } from 'core-app/features/hal/resources/version-resource';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { OpModalLocalsToken, OpModalService } from 'core-app/shared/components/modal/modal.service';
import { CardHighlightingMode } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting-mode.const';
import { Board } from './board';
import { VersionBoardHeaderComponent } from './board-actions/version/version-board-header.component';
import { BoardHighlightingTabComponent } from './configuration-modal/tabs/highlighting-tab.component';
import { BoardsMenuButtonComponent } from './toolbar-menu/boards-menu-button.component';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';

import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';

import { BoardsToolbarMenuDirective } from './toolbar-menu/boards-toolbar-menu.directive';
import { BoardService } from './board.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';

describe('board template contracts', () => {
  const locals:{ board?:Board } = {};
  const versionShowPath = vi.fn((id:string) => `/versions/${id}`);

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [CommonModule, FormsModule, OpenprojectHalModule],
      declarations: [VersionBoardHeaderComponent, BoardHighlightingTabComponent, BoardsMenuButtonComponent, BoardsToolbarMenuDirective, OpIconComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: PathHelperService, useValue: { versionShowPath } },
        { provide: OpModalLocalsToken, useValue: locals },
        { provide: OpModalService, useValue: {} },
        { provide: BoardService, useValue: {} },
        { provide: ToastService, useValue: {} },
        { provide: OPContextMenuService, useValue: {} },
      ],
    });
    versionShowPath.mockClear();
  });

  function board(mode:CardHighlightingMode = 'none'):Board {
    const grid = TestBed.inject(HalResourceService).createHalResource<GridResource>({ _type: 'Grid', widgets: [], options: { highlightingMode: mode }, _links: { self: { href: '/api/v3/grids/42' } } });
    return new Board(grid);
  }

  function header(id:string|null, status = 'open'):ComponentFixture<VersionBoardHeaderComponent> {
    const fixture = TestBed.createComponent(VersionBoardHeaderComponent);
    const version = TestBed.inject(HalResourceService).createHalResource<VersionResource>({ _type: 'Version', id, _links: { self: { href: id ? `/api/v3/versions/${id}` : null } } });
    version.name = 'Release';
    version.status = status;
    fixture.componentRef.setInput('resource', version);
    fixture.detectChanges();
    return fixture;
  }

  it('renders the persisted version link and locked state', () => {
    const fixture = header('42', 'locked');
    expect(fixture.nativeElement.querySelector('a')).toHaveAttribute('href', '/versions/42');
    expect(fixture.nativeElement.querySelector('.op-version-board-header')).toHaveClass('-locked');
  });

  it('keeps the version name without constructing a link for an absent identity', () => {
    const fixture = header(null);
    expect(fixture.nativeElement).toHaveTextContent('Release');
    expect(fixture.nativeElement.querySelector('a')).toBeNull();
    expect(versionShowPath).not.toHaveBeenCalled();
  });

  it('allows the dynamic header to wait for a resource', () => {
    const fixture = TestBed.createComponent(VersionBoardHeaderComponent);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('.op-version-board-header')).toBeNull();
    expect(versionShowPath).not.toHaveBeenCalled();
  });

  it.each<CardHighlightingMode>(['status', 'priority', 'type', 'inline', 'none'])('preserves the supported %s highlighting mode', (mode) => {
    const resource = board(mode);
    locals.board = resource;
    const component = TestBed.runInInjectionContext(() => new BoardHighlightingTabComponent());
    component.ngOnInit();
    component.onSave();
    expect(resource.highlightingMode).toBe(mode === 'inline' ? 'type' : mode);
  });

  it('selects priority and restores it after highlighting is toggled off', async () => {
    const resource = board('type');
    locals.board = resource;
    const fixture = TestBed.createComponent(BoardHighlightingTabComponent);
    fixture.detectChanges();
    await fixture.whenStable();
    const element:HTMLElement = fixture.nativeElement;
    const select = element.querySelector<HTMLSelectElement>('select')!;
    select.value = 'priority';
    select.dispatchEvent(new Event('change'));
    fixture.componentInstance.updateMode('none');
    fixture.componentInstance.updateMode('inline');
    fixture.componentInstance.onSave();
    expect(resource.highlightingMode).toBe('priority');
  });

  it('does not attach the toolbar menu before a board is emitted', () => {
    const fixture = TestBed.createComponent(BoardsMenuButtonComponent);
    fixture.componentRef.setInput('board$', new Subject<Board>());
    fixture.detectChanges();
    expect(fixture.debugElement.query(By.directive(BoardsToolbarMenuDirective))).toBeNull();
  });

  it('passes the emitted board unchanged to the toolbar menu', () => {
    const resource = board();
    const boards = new Subject<Board>();
    const fixture = TestBed.createComponent(BoardsMenuButtonComponent);
    fixture.componentRef.setInput('board$', boards);
    fixture.detectChanges();
    boards.next(resource);
    fixture.detectChanges();
    const menu = fixture.debugElement.query(By.directive(BoardsToolbarMenuDirective));
    expect(menu.injector.get(BoardsToolbarMenuDirective).board).toBe(resource);
  });
});
