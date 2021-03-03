import {
  ApplicationRef,
  ChangeDetectorRef,
  Component,
  ComponentFactoryResolver,
  ElementRef,
  Inject,
  Injector,
  OnDestroy,
  OnInit,
  ViewChild
} from '@angular/core';
import { OpModalLocalsMap } from 'core-app/modules/modal/modal.types';
import { OpModalComponent } from 'core-app/modules/modal/modal.component';
import { OpModalLocalsToken } from "core-app/modules/modal/modal.service";
import {
  ActiveTabInterface,
  TabComponent,
  TabInterface,
  TabPortalOutlet
} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { BoardConfigurationService } from "core-app/modules/boards/board/configuration-modal/board-configuration.service";
import { BoardService } from "core-app/modules/boards/board/board.service";
import { Board } from "core-app/modules/boards/board/board";


@Component({
  templateUrl: './board-configuration.modal.html'
})
export class BoardConfigurationModal extends OpModalComponent implements OnInit, OnDestroy  {

  /* Close on escape? */
  public closeOnEscape = false;

  /* Close on outside click */
  public closeOnOutsideClick = false;

  public text = {
    title: this.I18n.t('js.boards.configuration_modal.title'),
    closePopup: this.I18n.t('js.close_popup_title'),

    applyButton: this.I18n.t('js.modals.button_apply'),
    cancelButton: this.I18n.t('js.modals.button_cancel'),
  };

  // Get the view child we'll use as the portal host
  @ViewChild('tabContentOutlet', { static: true }) tabContentOutlet:ElementRef;
  // And a reference to the actual portal host interface
  public tabPortalHost:TabPortalOutlet;

  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly I18n:I18nService,
              readonly boardService:BoardService,
              readonly boardConfigurationService:BoardConfigurationService,
              readonly injector:Injector,
              readonly appRef:ApplicationRef,
              readonly componentFactoryResolver:ComponentFactoryResolver,
              readonly cdRef:ChangeDetectorRef,
              readonly elementRef:ElementRef) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    this.tabPortalHost = new TabPortalOutlet(
      this.boardConfigurationService.tabs,
      this.tabContentOutlet.nativeElement,
      this.componentFactoryResolver,
      this.appRef,
      this.injector
    );

    setTimeout(() => {
      const initialTab = this.availableTabs[0].name;
      this.switchTo(initialTab);
    });
  }

  ngOnDestroy() {
    this.tabPortalHost.dispose();
  }

  public get availableTabs():TabInterface[] {
    return this.tabPortalHost.availableTabs;
  }

  public get currentTab():ActiveTabInterface|null {
    return this.tabPortalHost.currentTab;
  }

  public switchTo(name:string) {
    this.tabPortalHost.switchTo(name);
  }

  public saveChanges():void {
    this.tabPortalHost.activeComponents.forEach((component:TabComponent) => {
      component.onSave();
    });

    const board = this.locals.board as Board;
    this.boardService
      .save(board)
      .subscribe(board => {
        this.service.close();
      });

  }

  /**
   * Called when the user attempts to close the modal window.
   * The service will close this modal if this method returns true
   * @returns {boolean}
   */
  public onClose():boolean {
    this.afterFocusOn.focus();
    return true;
  }

  protected get afterFocusOn():JQuery {
    return this.$element;
  }
}
