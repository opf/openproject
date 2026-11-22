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

import { AsyncPipe } from '@angular/common';
import { Component, ElementRef, forwardRef, inject, Input, output, viewChild } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { BehaviorSubject, NEVER, of, Subject } from 'rxjs';
import { type Mock } from 'vitest';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { BoardListsService } from 'core-app/features/boards/board/board-list/board-lists.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { QueryUpdatedService } from 'core-app/features/boards/board/query-updated/query-updated.service';
import { BoardActionsRegistryService } from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { States } from 'core-app/core/states/states.service';
import {
  BoardListCrossSelectionService,
} from 'core-app/features/boards/board/board-list/board-list-cross-selection.service';
import { BoardListComponent } from 'core-app/features/boards/board/board-list/board-list.component';
import { Board } from 'core-app/features/boards/board/board';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import {
  BoardPartitionedPageComponent,
} from 'core-app/features/boards/board/board-partitioned-page/board-partitioned-page.component';
import { BoardListContainerComponent } from './board-list-container.component';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'board-list',
  template: '<button #trigger type="button" (click)="deleteRequested.emit()">{{ resource.options.queryId }} menu</button>',
  providers: [{ provide: BoardListComponent, useExisting: forwardRef(() => FakeBoardListComponent) }],
})
class FakeBoardListComponent {
  @Input() resource:GridWidgetResource;

  @Input() board:Board;

  // eslint-disable-next-line @angular-eslint/no-output-on-prefix
  readonly onRemove = output<void>();

  readonly deleteRequested = output<void>();

  readonly visibilityChange = output<boolean>();

  readonly indicator = inject(ElementRef);

  private readonly trigger = viewChild.required<string, ElementRef<HTMLElement>>('trigger', { read: ElementRef });

  get menuTrigger():HTMLElement {
    return this.trigger().nativeElement;
  }
}

describe('BoardListContainerComponent list deletion', () => {
  let fixture:ComponentFixture<BoardListContainerComponent>;
  let deletion:Subject<void>;
  let handleRawError:Mock<HalResourceNotificationService['handleRawError']>;
  let save:Mock<BoardService['save']>;
  let board:Board;

  const widget = (queryId:string) => {
    const resource:Partial<GridWidgetResource> = { options: { queryId } };
    return resource as GridWidgetResource;
  };
  const menuButton = (name:string) => screen.getByRole('button', { name: `${name} menu` });

  beforeEach(async () => {
    deletion = new Subject<void>();
    handleRawError = vi.fn<HalResourceNotificationService['handleRawError']>();
    const grid:Partial<GridResource> = { widgets: [widget('First'), widget('Second')] };
    board = new Board(grid as GridResource);
    const boards = new BehaviorSubject(board);
    save = vi.fn<BoardService['save']>((saved) => {
      boards.next(saved);
      return of(saved);
    });

    TestBed.overrideComponent(BoardListContainerComponent, {
      set: {
        template: `
          @if ((board$ | async); as board) {
            @for (boardWidget of boardWidgets; track trackByQueryId($index, boardWidget)) {
              <board-list [resource]="boardWidget"
                [board]="board"
                (onRemove)="removeList(board, boardWidget)"
                (deleteRequested)="deleteList(board, boardWidget)"
                (visibilityChange)="changeVisibilityOfList(board, boardWidget, $event)" />
            }
            <div #addListControl role="button" tabindex="0">Add list</div>
          }
        `,
        providers: [{ provide: BoardListCrossSelectionService, useValue: { selections: () => NEVER } }],
      },
    });
    await TestBed.configureTestingModule({
      declarations: [BoardListContainerComponent],
      imports: [AsyncPipe, FakeBoardListComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: ToastService, useValue: { addSuccess: () => undefined } },
        { provide: HalResourceNotificationService, useValue: { handleRawError } },
        { provide: BoardPartitionedPageComponent, useValue: { cdRef: { detectChanges: () => undefined } } },
        { provide: BoardListsService, useValue: {} },
        { provide: BoardActionsRegistryService, useValue: {} },
        { provide: OpModalService, useValue: {} },
        { provide: QueryUpdatedService, useValue: { monitor: () => NEVER } },
        { provide: PathHelperService, useValue: {} },
        { provide: CurrentProjectService, useValue: {} },
        { provide: States, useValue: {} },
        { provide: BoardService, useValue: { currentBoard$: new Subject<string>(), save } },
        {
          provide: ApiV3Service,
          useValue: {
            boards: { id: () => ({ requireAndStream: () => boards }) },
            queries: { id: () => ({ delete: () => deletion }) },
          },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(BoardListContainerComponent);
    fixture.componentRef.setInput('boardId', '1');
    await fixture.whenStable();
  });

  afterEach(() => fixture.destroy());

  const finishDeletion = async () => {
    deletion.next();
    deletion.complete();
    await fixture.whenStable();
  };

  it('focuses the next list menu once the list is deleted', async () => {
    await userEvent.click(menuButton('First'));

    await finishDeletion();

    expect(screen.queryByRole('button', { name: 'First menu' })).not.toBeInTheDocument();
    expect(menuButton('Second')).toHaveFocus();
  });

  it('focuses Add list once the last list is deleted', async () => {
    await userEvent.click(menuButton('Second'));
    await finishDeletion();
    deletion = new Subject<void>();
    await userEvent.click(menuButton('First'));

    await finishDeletion();

    expect(screen.getByRole('button', { name: 'Add list' })).toHaveFocus();
  });

  it('leaves focus alone when the user clicked while the deletion was pending', async () => {
    await userEvent.click(menuButton('First'));

    fireEvent.pointerDown(document.body);
    menuButton('First').blur();
    await finishDeletion();

    expect(menuButton('Second')).not.toHaveFocus();
  });

  it('keeps the list and its menu focus and reports the error when the deletion fails', async () => {
    await userEvent.click(menuButton('First'));

    deletion.error(new Error('forbidden'));
    await fixture.whenStable();

    expect(menuButton('First')).toHaveFocus();
    expect(save).not.toHaveBeenCalled();
    expect(handleRawError).toHaveBeenCalledTimes(1);
  });

  it('still saves the board but leaves focus alone when the board is closed before the deletion completes', async () => {
    await userEvent.click(menuButton('First'));
    const second = menuButton('Second');

    fixture.destroy();
    menuButton('First').blur();
    await finishDeletion();

    expect(save).toHaveBeenCalledExactlyOnceWith(board);
    expect(second).not.toHaveFocus();
  });
});
