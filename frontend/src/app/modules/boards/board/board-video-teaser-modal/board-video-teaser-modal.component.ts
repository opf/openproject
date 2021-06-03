import { ChangeDetectorRef, Component, ElementRef, Inject, OnDestroy, OnInit } from '@angular/core';
import { OpModalLocalsMap } from 'core-app/modules/modal/modal.types';
import { OpModalComponent } from 'core-app/modules/modal/modal.component';
import { OpModalLocalsToken } from "core-app/modules/modal/modal.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { boardTeaserVideoURL } from "core-app/modules/boards/board-constants.const";
import { DomSanitizer } from "@angular/platform-browser";


@Component({
  template: `
    <div class="op-modal--portal">
      <div class="op-modal--modal-container"
           data-indicator-name="modal"
           tabindex="0">
        <div class="op-modal--modal-header">
          <h3 [textContent]="text.title"></h3>

          <a class="op-modal--modal-close-button">
            <i
              class="icon-close"
              (click)="closeMe($event)"
              [attr.title]="text.closePopup">
            </i>
          </a>
        </div>

        <iframe [src]="teaserVideoUrl"
                width="800"
                height="500"
                class="boards--teaser-video"
                frameborder="0"
                allow="autoplay; fullscreen"
                allowfullscreen>
        </iframe>
      </div>
    </div>

  `
})
export class BoardVideoTeaserModalComponent extends OpModalComponent implements OnInit, OnDestroy {

  /* Close on escape? */
  public closeOnEscape = false;

  /* Close on outside click? */
  public closeOnOutsideClick = false;

  public text:any = {
    title: this.I18n.t('js.label_board_plural')
  };

  public teaserVideoUrl = this.domSanitizer.bypassSecurityTrustResourceUrl(boardTeaserVideoURL);

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService,
              readonly domSanitizer:DomSanitizer) {

    super(locals, cdRef, elementRef);
  }
}
