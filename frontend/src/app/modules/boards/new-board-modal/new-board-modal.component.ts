// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {OpModalComponent} from "core-components/op-modals/op-modal.component";
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import {ChangeDetectorRef, Component, ElementRef, Inject, ViewChild} from "@angular/core";
import {OpModalLocalsMap} from "core-components/op-modals/op-modal.types";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BoardType} from "core-app/modules/boards/board/board";
import {StateService} from "@uirouter/core";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {BoardActionsRegistryService} from "core-app/modules/boards/board/board-actions/board-actions-registry.service";

@Component({
  templateUrl: './new-board-modal.html'
})
export class NewBoardModalComponent extends OpModalComponent {
  @ViewChild('actionAttributeSelect') actionAttributeSelect:ElementRef;

  public showClose:boolean;

  public confirmed = false;

  public available = this.boardActions.available();

  public text:any = {
    title: this.I18n.t('js.boards.new_board'),
    button_continue: this.I18n.t('js.button_continue'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title'),


    free_board: this.I18n.t('js.boards.board_type.free'),
    free_board_text: this.I18n.t('js.boards.board_type.free_text'),

    action_board: this.I18n.t('js.boards.board_type.action'),
    action_board_text: this.I18n.t('js.boards.board_type.action_text'),
    select_attribute: this.I18n.t('js.boards.board_type.select_attribute'),
    placeholder: this.I18n.t('js.placeholders.selection'),
  };

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly state:StateService,
              readonly boardService:BoardService,
              readonly boardActions:BoardActionsRegistryService,
              readonly boardCache:BoardCacheService,
              readonly I18n:I18nService) {

    super(locals, cdRef, elementRef);
  }

  createFree() {
    this.create({ type: 'free' });
  }

  createAction() {
    this.create({ type: 'action', attribute: this.actionAttributeSelect.nativeElement.value! });
  }

  private create(params:{ type:BoardType, attribute?:string }) {
    this.boardService
      .create(params)
      .then((board) => {
        this.closeMe();
        this.boardCache.update(board);
        this.state.go('boards.show', { board_id: board.id, isNew: true });
      });
  }
}

