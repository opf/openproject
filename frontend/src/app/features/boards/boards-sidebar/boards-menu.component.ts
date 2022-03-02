import {
  Component,
  Injector,
  OnInit,
} from '@angular/core';
import { Observable } from 'rxjs';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { Board } from 'core-app/features/boards/board/board';
import { compareByAttribute } from 'core-app/shared/helpers/angular/tracking-functions';
import { map } from 'rxjs/operators';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { MainMenuNavigationService } from 'core-app/core/main-menu/main-menu-navigation.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { NewBoardModalComponent } from 'core-app/features/boards/new-board-modal/new-board-modal.component';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';

export const boardsMenuSelector = 'boards-menu';

@Component({
  selector: boardsMenuSelector,
  templateUrl: './boards-menu.component.html',
})

export class BoardsMenuComponent extends UntilDestroyedMixin implements OnInit {
  trackById = compareByAttribute('id');

  currentProjectIdentifier = this.currentProject.identifier;

  selectedBoardId:string;

  boards$:Observable<Board[]> = this
    .apiV3Service
    .boards
    .observeAll()
    .pipe(
      map((boards:Board[]) => boards.sort((a, b) => a.name.localeCompare(b.name))),
    );

  canCreateBoards$ = this
    .currentUserService
    .hasCapabilities$(
      'boards/create',
      this.currentProject.id || undefined,
      )
    .pipe(this.untilDestroyed());

  text = {
    create_new_board: this.I18n.t('js.boards.create_new'),
  };

  constructor(
    private readonly boardService:BoardService,
    private readonly apiV3Service:ApiV3Service,
    private readonly currentProject:CurrentProjectService,
    private readonly mainMenuService:MainMenuNavigationService,
    readonly currentUserService:CurrentUserService,
    readonly I18n:I18nService,
    private readonly opModalService:OpModalService,
    private readonly injector:Injector,
  ) {
    super();
  }

  ngOnInit():void {
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

  showNewBoardModal():void {
    this.opModalService.show(NewBoardModalComponent, this.injector);
  }

  private focusBackArrow():void {
    const buttonArrowLeft = jQuery('*[data-name="board_view"] .main-menu--arrow-left-to-project');
    buttonArrowLeft.focus();
  }
}
