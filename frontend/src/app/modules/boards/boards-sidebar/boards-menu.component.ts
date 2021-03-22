import { Component, OnInit } from "@angular/core";
import { Observable } from "rxjs";
import { BoardService } from "core-app/modules/boards/board/board.service";
import { Board } from "core-app/modules/boards/board/board";
import { AngularTrackingHelpers } from "core-components/angular/tracking-functions";
import { MainMenuNavigationService } from "core-components/main-menu/main-menu-navigation.service";
import { map } from "rxjs/operators";
import { CurrentProjectService } from "core-components/projects/current-project.service";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

export const boardsMenuSelector = 'boards-menu';

@Component({
  selector: boardsMenuSelector,
  templateUrl: './boards-menu.component.html'
})

export class BoardsMenuComponent extends UntilDestroyedMixin implements OnInit {
  trackById = AngularTrackingHelpers.compareByAttribute('id');

  currentProjectIdentifier = this.currentProject.identifier;

  selectedBoardId:string;

  public boards$:Observable<Board[]> = this
    .apiV3Service
    .boards
    .observeAll()
    .pipe(
      map((boards:Board[]) => {
        return boards.sort(function (a, b) {
          if (a.name < b.name) {
            return -1;
          }
          if (a.name > b.name) {
            return 1;
          }
          return 0;
        });
      })
    );

  constructor(private readonly boardService:BoardService,
              private readonly apiV3Service:APIV3Service,
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
        this.untilDestroyed()
      )
      .subscribe((id:string|null) => {
        this.selectedBoardId = id ? id : '';
      });
  }

  private focusBackArrow() {
    const buttonArrowLeft = jQuery('*[data-name="board_view"] .main-menu--arrow-left-to-project');
    buttonArrowLeft.focus();
  }
}
