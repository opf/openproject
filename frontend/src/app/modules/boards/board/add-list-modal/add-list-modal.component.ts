//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

import { ChangeDetectorRef, Component, ElementRef, Inject, OnInit } from "@angular/core";
import { OpModalLocalsMap } from "core-app/modules/modal/modal.types";
import { OpModalComponent } from "core-app/modules/modal/modal.component";
import { OpModalLocalsToken } from "core-app/modules/modal/modal.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { Board } from "core-app/modules/boards/board/board";
import { StateService } from "@uirouter/core";
import { BoardService } from "core-app/modules/boards/board/board.service";
import { BoardActionsRegistryService } from "core-app/modules/boards/board/board-actions/board-actions-registry.service";
import { BoardActionService } from "core-app/modules/boards/board/board-actions/board-action.service";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { AngularTrackingHelpers } from "core-components/angular/tracking-functions";
import { CreateAutocompleterComponent } from "core-app/modules/autocompleter/create-autocompleter/create-autocompleter.component.ts";
import { of } from "rxjs";
import { DebouncedRequestSwitchmap, errorNotificationHandler } from "core-app/helpers/rxjs/debounced-input-switchmap";
import { ValueOption } from "core-app/modules/fields/edit/field-types/select-edit-field.component";
import { HalResourceNotificationService } from "core-app/modules/hal/services/hal-resource-notification.service";

@Component({
  templateUrl: './add-list-modal.html'
})
export class AddListModalComponent extends OpModalComponent implements OnInit {
  /** Keep a switchmap for search term and loading state */
  public requests = new DebouncedRequestSwitchmap<string, ValueOption>(
    (searchTerm:string) => this.actionService.loadAvailable(this.board, this.active, searchTerm),
    errorNotificationHandler(this.halNotification),
    true
  );

  public showClose:boolean;

  public confirmed = false;

  /** Active board */
  public board:Board;

  /** Current active set of values */
  public active:Set<string>;

  /** Action service used by the board */
  public actionService:BoardActionService;

  /** The selected attribute */
  public selectedAttribute:HalResource|undefined;

  /** avoid double click */
  public inFlight = false;

  public trackByHref = AngularTrackingHelpers.trackByHref;

  /* Do not close on outside click (because the select option are appended to the body */
  public closeOnOutsideClick = false;

  public warningText:string|undefined;

  public text:any = {
    title: this.I18n.t('js.boards.add_list'),
    button_add: this.I18n.t('js.button_add'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title'),

    free_board: this.I18n.t('js.boards.board_type.free'),
    free_board_text: this.I18n.t('js.boards.board_type.free_text'),

    action_board: this.I18n.t('js.boards.board_type.action'),
    action_board_text: this.I18n.t('js.boards.board_type.action_text'),
    select_attribute: this.I18n.t('js.boards.board_type.select_attribute'),
    placeholder: this.I18n.t('js.placeholders.selection'),
  };

  public referenceOutputs = {
    onCreate: (value:HalResource) => this.onNewActionCreated(value),
    onOpen: () => this.requests.input$.next(''),
    onChange: (value:HalResource) => this.onModelChange(value),
    onAfterViewInit: (component:CreateAutocompleterComponent) => component.focusInputField()
  };

  /** The loaded available values */
  availableValues:any;

  /** Whether the no results warning is displayed */
  showWarning = false;

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly boardActions:BoardActionsRegistryService,
              readonly halNotification:HalResourceNotificationService,
              readonly state:StateService,
              readonly boardService:BoardService,
              readonly I18n:I18nService) {

    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();

    this.board = this.locals.board;
    this.active = new Set(this.locals.active as string[]);
    this.actionService = this.boardActions.get(this.board.actionAttribute!);


    this
      .requests
      .output$
      .pipe(
        this.untilDestroyed()
      )
      .subscribe((values:unknown[]) => {
        let hasMember = false;
        if (values.length === 0) {
          if (this.requests.lastRequestedValue !== undefined && this.requests.lastRequestedValue !== '') {
            hasMember = true;
          } else {
            hasMember = false;
          }
        } else {
          hasMember = false;
        }
        this.actionService
          .warningTextWhenNoOptionsAvailable(hasMember)
          .then((text) => {
            this.warningText = text;
          });
        this.availableValues = values;
        this.showWarning = this.requests.lastRequestedValue !== undefined && (values.length === 0);
        this.cdRef.detectChanges();
      });

    // Request an empty value to load warning early on
    this.requests.input$.next('');
  }

  onModelChange(element:HalResource) {
    this.selectedAttribute = element;
  }

  create() {
    this.inFlight = true;
    this.actionService
      .addColumnWithActionAttribute(this.board, this.selectedAttribute!)
      .then(board => this.boardService.save(board).toPromise())
      .then((board) => {
        this.inFlight = false;
        this.closeMe();
        this.state.go('boards.partitioned.show', { board_id: board.id, isNew: true });
      })
      .catch(() => this.inFlight = false);
  }

  onNewActionCreated(newValue:HalResource) {
    this.selectedAttribute = newValue;
    this.create();
  }

  autocompleterComponent() {
    return this.actionService.autocompleterComponent();
  }
}

