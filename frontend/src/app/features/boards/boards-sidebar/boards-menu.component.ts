import {
  Component,
  HostBinding,
  Injector,
  OnInit,
} from '@angular/core';
import { Observable } from 'rxjs';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { Board } from 'core-app/features/boards/board/board';
import { map } from 'rxjs/operators';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { MainMenuNavigationService } from 'core-app/core/main-menu/main-menu-navigation.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { IOpSidemenuItem } from 'core-app/shared/components/sidemenu/sidemenu.component';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

export const boardsMenuSelector = 'boards-menu';

@Component({
  selector: boardsMenuSelector,
  templateUrl: './boards-menu.component.html',
})

export class BoardsMenuComponent extends UntilDestroyedMixin implements OnInit {
  @HostBinding('class.op-sidebar') className = true;

  boardOptions$:Observable<IOpSidemenuItem[]> = this
    .apiV3Service
    .boards
    .observeAll()
    .pipe(
      map((boards:Board[]) => {
        const menuItems:IOpSidemenuItem[] = boards.map((board) => ({
          title: board.name,
          uiSref: 'boards.partitioned.show',
          uiParams: {
            board_id: board.id,
            query_props: '',
            projects: 'projects',
            projectPath: this.currentProject.identifier,
          },
          uiOptions: { reload: true },
        }));

        return menuItems.sort((a, b) => a.title.localeCompare(b.title));
      }),
    );

  canCreateBoards$ = this
    .currentUserService
    .hasCapabilities$(
      'boards/create',
      this.currentProject.id || null,
    )
    .pipe(this.untilDestroyed());

  text = {
    board: this.I18n.t('js.label_board'),
    create_new_board: this.I18n.t('js.boards.create_new'),
  };

  constructor(
    readonly boardService:BoardService,
    readonly apiV3Service:ApiV3Service,
    readonly currentProject:CurrentProjectService,
    readonly mainMenuService:MainMenuNavigationService,
    readonly currentUserService:CurrentUserService,
    readonly I18n:I18nService,
    readonly pathHelper:PathHelperService
  ) {
    super();
  }

  ngOnInit():void {
    // When activating the boards submenu,
    // either initially or through click on the toggle, load the results
    this.mainMenuService
      .onActivate('boards')
      .subscribe(() => {
        this.focusBackArrow();
        void this.boardService.loadAllBoards();
      });
  }

  redirectToNewBoardForm():void {
    window.location.href = this.pathHelper.newBoardsPath(this.currentProject.identifier);
  }

  private focusBackArrow():void {
    const buttonArrowLeft = jQuery('*[data-name="boards"] .main-menu--arrow-left-to-project');
    buttonArrowLeft.focus();
  }
}
