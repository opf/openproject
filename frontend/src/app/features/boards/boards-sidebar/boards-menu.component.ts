import { Component, OnInit } from '@angular/core';
import { Observable } from 'rxjs';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { Board } from 'core-app/features/boards/board/board';
import { compareByAttribute } from 'core-app/shared/helpers/angular/tracking-functions';
import { map } from 'rxjs/operators';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { MainMenuNavigationService } from 'core-app/core/main-menu/main-menu-navigation.service';

export const boardsMenuSelector = 'boards-menu';

@Component({
  selector: boardsMenuSelector,
  templateUrl: './boards-menu.component.html',
})

export class BoardsMenuComponent extends UntilDestroyedMixin implements OnInit {
  trackById = compareByAttribute('id');

  currentProjectIdentifier = this.currentProject.identifier;

  selectedBoardId:string;

  public boards$:Observable<Board[]> = this
    .apiV3Service
    .boards
    .observeAll()
    .pipe(
      map((boards:Board[]) => boards.sort((a, b) => a.name.localeCompare(b.name))),
    );

  constructor(private readonly boardService:BoardService,
    private readonly apiV3Service:ApiV3Service,
    private readonly currentProject:CurrentProjectService,
    private readonly mainMenuService:MainMenuNavigationService) {
    super();
  }

  ngOnInit() {
    // When activating the boards submenu,
    // either initially or through click on the toggle, load the results
    this.mainMenuService
      .onActivate('board_view')
      .subscribe(() => {
        this.focusBackArrow();
        this.boardService.loadAllBoards();
      });

    this
      .boardService
      .currentBoard$
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((id:string|null) => {
        this.selectedBoardId = id || '';
      });
  }

  private focusBackArrow() {
    const buttonArrowLeft = jQuery('*[data-name="board_view"] .main-menu--arrow-left-to-project');
    buttonArrowLeft.focus();
  }
}
