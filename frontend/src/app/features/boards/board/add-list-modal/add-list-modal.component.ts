//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, OnInit, ViewChild, inject } from '@angular/core';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Board } from 'core-app/features/boards/board/board';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { BoardActionsRegistryService } from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { tap } from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  firstValueFrom,
  Observable,
} from 'rxjs';
import { OpAutocompleterComponent } from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

@Component({
  templateUrl: './add-list-modal.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class AddListModalComponent extends OpModalComponent implements OnInit {
  readonly boardActions = inject(BoardActionsRegistryService);
  readonly halNotification = inject(HalResourceNotificationService);
  readonly boardService = inject(BoardService);
  readonly I18n = inject(I18nService);
  readonly apiV3Service = inject(ApiV3Service);
  readonly currentProject = inject(CurrentProjectService);
  readonly pathHelper = inject(PathHelperService);

  @ViewChild(OpAutocompleterComponent, { static: true }) public ngSelectComponent:OpAutocompleterComponent;

  getAutocompleterData = (searchTerm:string):Observable<HalResource[]> => {
    // Remove prefix # from search
    searchTerm = searchTerm.replace(/^#/, '');
    return this.actionService.loadAvailable(this.active, searchTerm)
      .pipe(tap((values) => (this.warnIfNoOptions(values))));
  };

  public autocompleterOptions = {
    resource: '',
    getOptionsFn: this.getAutocompleterData,
  };

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

  public warningText:string|undefined;

  public text:any = {
    title: this.I18n.t('js.boards.add_list'),
    button_add: this.I18n.t('js.button_add'),
    button_create: this.I18n.t('js.button_create'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title'),

    free_board: this.I18n.t('js.boards.board_type.free'),
    free_board_text: this.I18n.t('js.boards.board_type.free_text'),

    action_board: this.I18n.t('js.boards.board_type.action'),
    action_board_text: this.I18n.t('js.boards.board_type.action_text'),
    select_attribute: this.I18n.t('js.boards.board_type.select_attribute'),
    placeholder: this.I18n.t('js.placeholders.selection'),
  };

  /** Whether the no results warning is displayed */
  showWarning = false;

  ngOnInit() {
    super.ngOnInit();
    this.board = this.locals.board;
    this.active = new Set(this.locals.active as string[]);
    this.actionService = this.boardActions.get(this.board.actionAttribute!);
    this.autocompleterOptions.resource = this.actionService.resourceName.toLowerCase();
  }

  onModelChange(element:HalResource) {
    this.selectedAttribute = element;
  }

  create() {
    this.inFlight = true;
    this.actionService
      .addColumnWithActionAttribute(this.board, this.selectedAttribute!)
      .then((board) => firstValueFrom(this.boardService.save(board)))
      .then((board) => {
        this.inFlight = false;
        this.closeMe();
        void Turbo.visit(`${this.pathHelper.boardsPath(this.currentProject.identifier)}/${board.id}`);
      })
      .catch(() => {
        this.inFlight = false;
        this.cdRef.detectChanges();
      });
  }

  onNewActionCreated() {
    this
      .apiV3Service
      .versions
      .post(this.getVersionPayload(this.ngSelectComponent.ngSelectInstance.searchTerm))
      .subscribe(
        (version) => {
          this.selectedAttribute = version;
          this.create();
        },
        (error) => {
          this.ngSelectComponent.closeSelect();
          this.halNotification.handleRawError(error);
        },
      );
  }

  private getVersionPayload(name:string) {
    const payload:any = {};
    payload.name = name;
    payload._links = {
      definingProject: {
        href: this.apiV3Service.projects.id(this.currentProject.id!).path,
      },
    };

    return payload;
  }

  private warnIfNoOptions(values:unknown[]) {
    let hasMember = false;
    if (values.length === 0) {
      if (this.ngSelectComponent.ngSelectInstance.searchTerm !== undefined && this.ngSelectComponent.ngSelectInstance.searchTerm !== '') {
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
        this.cdRef.detectChanges();
      })
      .catch(() => {});
    this.showWarning = this.ngSelectComponent.ngSelectInstance.searchTerm !== undefined && (values.length === 0);
    this.ngSelectComponent.repositionDropdown();
    this.cdRef.detectChanges();
  }
}
