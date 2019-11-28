import {Component, OnInit} from "@angular/core";
import {Observable} from "rxjs";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {Board} from "core-app/modules/boards/board/board";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";
import {MainMenuNavigationService} from "core-components/main-menu/main-menu-navigation.service";
import {map} from "rxjs/operators";
import {CurrentProjectService} from "core-components/projects/current-project.service";

@Component({
  selector: 'boards-menu',
  templateUrl: './boards-menu.component.html'
})

export class BoardsMenuComponent implements OnInit {
  trackById = AngularTrackingHelpers.compareByAttribute('id');

  currentProjectIdentifier = this.currentProject.identifier;

  public boards$:Observable<Board[]> = this.boardCache.observeAll().pipe(
    map((boards:Board[]) => {
      return boards.sort(function(a, b){
        if(a.name < b.name) { return -1; }
        if(a.name > b.name) { return 1; }
        return 0;
      });
    })
  );

  constructor(private readonly boardService:BoardService,
              private readonly boardCache:BoardCacheService,
              private readonly currentProject:CurrentProjectService,
              private readonly mainMenuService:MainMenuNavigationService) {
  }

  ngOnInit() {
    // When activating the work packages submenu,
    // either initially or through click on the toggle, load the results
    this.mainMenuService
      .onActivate('board_view')
      .subscribe(() => {
        this.focusBackArrow();
        this.boardService.loadAllBoards()
      });
  }

  private focusBackArrow() {
    let buttonArrowLeft = jQuery('*[data-name="board_view"] .main-menu--arrow-left-to-project');
    buttonArrowLeft.focus();
  }
}
DynamicBootstrapper.register({selector: 'boards-menu', cls: BoardsMenuComponent});
