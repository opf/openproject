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
import {ChangeDetectorRef, Component, ElementRef, Inject, ViewChild} from "@angular/core";
import {OpModalLocalsMap} from "core-components/op-modals/op-modal.types";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BoardType} from "core-app/modules/boards/board/board";
import {StateService} from "@uirouter/core";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {BoardActionsRegistryService} from "core-app/modules/boards/board/board-actions/board-actions-registry.service";
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import { ITileViewEntry } from '../tile-view/tile-view.component';


@Component({
  templateUrl: './new-board-modal.html',
})
export class NewBoardModalComponent extends OpModalComponent {
  @ViewChild('actionAttributeSelect', { static: true }) actionAttributeSelect:ElementRef;

  public showClose:boolean = true;

  public confirmed = false;

  public available = this.boardActions.available();

  public inFlight = false;

  public text:any = {
    close_popup: this.I18n.t('js.close_popup_title'),

    free_board: this.I18n.t('js.boards.board_type.free'),
    free_board_text: this.I18n.t('js.boards.board_type.free_text'),
    board_type: this.I18n.t('js.boards.board_type.text'),

    action_board: this.I18n.t('js.boards.board_type.action'),
    action_board_text: this.I18n.t('js.boards.board_type.action_text'),
    select_attribute: this.I18n.t('js.boards.board_type.select_attribute'),
    select_board_type: this.I18n.t('js.boards.board_type.select_board_type'),
    placeholder: this.I18n.t('js.placeholders.selection'),
  };

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly state:StateService,
              readonly boardService:BoardService,
              readonly boardActions:BoardActionsRegistryService,
              readonly halNotification:HalResourceNotificationService,
              readonly loadingIndicatorService:LoadingIndicatorService,
              readonly I18n:I18nService,
              readonly boardActionRegistry:BoardActionsRegistryService) {

    super(locals, cdRef, elementRef);
    this.initiateTiles();
  }

  public createBoard(attribute:string) {
    if (attribute === 'basic') {
    this.createFree();
    }
    else {
      this.createAction(attribute);
    }
  }
  private initiateTiles() {
    this.available.unshift({attribute:'basic', text:this.text.free_board,
    icon:'icon-boards', description:this.text.free_board_text});
    this.addIcon(this.available);
    this.addDescription(this.available);
    this.addText(this.available);
  }
  private createFree() {
    this.create({ type: 'free' });
  }

  private createAction(attribute:string) {
    this.create({ type: 'action', attribute: attribute! });
  }

  private create(params:{ type:BoardType, attribute?:string }) {
    this.inFlight = true;

    this.loadingIndicatorService.modal.promise = this.boardService
      .create(params)
      .then((board) => {
        this.inFlight = false;
        this.closeMe();
        this.state.go('boards.partitioned.show', { board_id: board.id, isNew: true });
      })
      .catch((error:unknown) => {
        this.inFlight = false;
        this.halNotification.handleRawError(error);
      });
  }
  private addDescription(tiles:ITileViewEntry[]) {
    tiles.forEach(element => {
      if (element.attribute !== 'basic') {
        const service = this.boardActionRegistry.get(element.attribute!);
        element.description = service.description; }
    });
  }
  private addIcon(tiles:ITileViewEntry[]) {
    tiles.forEach(element => {
      if (element.attribute !== 'basic') {
        const service = this.boardActionRegistry.get(element.attribute!);
        element.icon = service.icon;
      }
    });
  }
  private addText(tiles:ITileViewEntry[]) {
    tiles.forEach(element => {
      if (element.attribute !== 'basic') {
        const service = this.boardActionRegistry.get(element.attribute!);
        element.text = service.text;
      }
    });
  }
}
