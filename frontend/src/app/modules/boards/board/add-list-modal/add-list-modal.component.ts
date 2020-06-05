// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// ++

import {OpModalComponent} from "core-components/op-modals/op-modal.component";
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import {ChangeDetectorRef, Component, ElementRef, Inject, OnInit} from "@angular/core";
import {OpModalLocalsMap} from "core-components/op-modals/op-modal.types";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Board} from "core-app/modules/boards/board/board";
import {StateService} from "@uirouter/core";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {BoardActionsRegistryService} from "core-app/modules/boards/board/board-actions/board-actions-registry.service";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";
import {CreateAutocompleterComponent} from "core-app/modules/common/autocomplete/create-autocompleter.component";

@Component({
  templateUrl: './add-list-modal.html'
})
export class AddListModalComponent extends OpModalComponent implements OnInit {
  public showClose:boolean;

  public confirmed = false;

  /** Active board */
  public board:Board;

  /** Current active set of values */
  public active:Set<string>;

  /** Action service used by the board */
  public actionService:BoardActionService;

  /** Remaining available values */
  public availableValues:HalResource[] = [];

  /** The selected attribute */
  public selectedAttribute:HalResource|undefined;

  /** avoid double click */
  public inFlight = false;

  public trackByHref = AngularTrackingHelpers.trackByHref;

  /* Do not close on outside click (because the select option are appended to the body */
  public closeOnOutsideClick = false;

  public valuesAvailable:boolean = true;

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
    onChange: (value:HalResource) => this.onModelChange(value),
    onAfterViewInit: (component:CreateAutocompleterComponent) => component.focusInputField()
  };

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly boardActions:BoardActionsRegistryService,
              readonly state:StateService,
              readonly boardService:BoardService,
              readonly boardCache:BoardCacheService,
              readonly I18n:I18nService) {

    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();

    this.board = this.locals.board;
    this.active = new Set(this.locals.active as string[]);
    this.actionService = this.boardActions.get(this.board.actionAttribute!);

    this.actionService
      .getAvailableValues(this.board, this.active)
      .then(available => {
        this.availableValues = available;
        if (this.availableValues.length === 0) {
          this.actionService
            .warningTextWhenNoOptionsAvailable()
            .then((text) => {
              this.warningText = text;
              this.valuesAvailable = false;
            });
        }
      });
  }

  onModelChange(element:HalResource) {
    this.selectedAttribute = element;
  }

  create() {
    this.inFlight = true;
    this.actionService
      .addActionQuery(this.board, this.selectedAttribute!)
      .then(board => this.boardService.save(board))
      .then((board) => {
        this.inFlight = false;
        this.closeMe();
        this.boardCache.update(board);
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

