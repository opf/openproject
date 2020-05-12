import {AfterViewInit, Component, Injector, OnInit} from "@angular/core";
import {Observable} from "rxjs";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {Board} from "core-app/modules/boards/board/board";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {NewBoardModalComponent} from "core-app/modules/boards/new-board-modal/new-board-modal.component";
import {BannersService} from "core-app/modules/common/enterprise/banners.service";
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {AuthorisationService} from "core-app/modules/common/model-auth/model-auth.service";
import {enterpriseDemoUrl, enterpriseEditionUrl} from "core-app/globals/constants.const";
import {DomSanitizer} from "@angular/platform-browser";
import {boardTeaserVideoURL} from "core-app/modules/boards/board-constants.const";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {componentDestroyed} from "@w11k/ngx-componentdestroyed";

@Component({
  templateUrl: './boards-index-page.component.html',
  styleUrls: ['./boards-index-page.component.sass']
})
export class BoardsIndexPageComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit {

  public text = {
    name: this.I18n.t('js.modals.label_name'),
    board: this.I18n.t('js.label_board'),
    boards: this.I18n.t('js.label_board_plural'),
    type: this.I18n.t('js.boards.label_board_type'),
    type_free: this.I18n.t('js.boards.board_type.free'),
    action_by_attribute: (attr:string) => this.I18n.t('js.boards.board_type.action_by_attribute',
      { attribute: this.I18n.t('js.boards.board_type.action_type.' + attr ) }),
    createdAt: this.I18n.t('js.label_created_on'),
    delete: this.I18n.t('js.button_delete'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
    deleteSuccessful: this.I18n.t('js.notice_successful_delete'),
    noResults: this.I18n.t('js.notice_no_results_to_display'),

    teaser_text: this.I18n.t('js.boards.upsale.teaser_text'),
    enterprise: this.I18n.t('js.boards.upsale.upgrade_to_ee_text'),
    upgrade: this.I18n.t('js.boards.upsale.upgrade'),
    personal_demo: this.I18n.t('js.boards.upsale.personal_demo'),
  };

  public canAdd = false;

  public boards$:Observable<Board[]> = this.boardCache.observeAll();

  teaserVideoURL = this.domSanitizer.bypassSecurityTrustResourceUrl(boardTeaserVideoURL);

  constructor(private readonly boardService:BoardService,
              private readonly boardCache:BoardCacheService,
              private readonly I18n:I18nService,
              private readonly notifications:NotificationsService,
              private readonly opModalService:OpModalService,
              private readonly loadingIndicatorService:LoadingIndicatorService,
              private readonly authorisationService:AuthorisationService,
              private readonly injector:Injector,
              private readonly bannerService:BannersService,
              private readonly domSanitizer:DomSanitizer) {
    super();
  }

  ngOnInit():void {
    this.authorisationService
      .observeUntil(componentDestroyed(this))
      .subscribe(() => {
        this.canAdd = this.authorisationService.can('boards', 'create');
      });
  }

  ngAfterViewInit():void {
    const loadingIndicator = this.loadingIndicatorService.indicator('boards-module');
    loadingIndicator.promise = this.boardService.loadAllBoards();
  }

  newBoard() {
    this.opModalService.show(NewBoardModalComponent, this.injector);
  }

  destroyBoard(board:Board) {
    if (!window.confirm(this.text.areYouSure)) {
      return;
    }

    this.boardService
      .delete(board)
      .then(() => {
        this.boardCache.clearSome(board.id!);
        this.notifications.addSuccess(this.text.deleteSuccessful);
      })
      .catch((error) => this.notifications.addError("Deletion failed: " + error));
  }

  public showBoardIndexView() {
    return !this.bannerService.eeShowBanners;
  }

  public eeLink() {
    return enterpriseEditionUrl + '&op_referrer=boards';
  }

  public demoLink() {
    return enterpriseDemoUrl;
  }
}
