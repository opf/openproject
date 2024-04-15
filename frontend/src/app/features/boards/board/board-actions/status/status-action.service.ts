import { Injectable } from '@angular/core';
import { Board } from 'core-app/features/boards/board/board';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { CachedBoardActionService } from 'core-app/features/boards/board/board-actions/cached-board-action.service';
import { StatusBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/status/status-board-header.component';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { map } from 'rxjs/operators';
import { Observable } from 'rxjs';

@Injectable()
export class BoardStatusActionService extends CachedBoardActionService {
  filterName = 'status';

  resourceName = 'status';

  text = this.I18n.t('js.boards.board_type.board_type_title.status');

  description = this.I18n.t('js.boards.board_type.action_text_status');

  label = this.I18n.t('js.boards.add_list_modal.labels.status');

  icon = 'icon-workflow';

  image = imagePath('board_creation_modal/status.svg');

  localizedName = this.I18n.t('js.work_packages.properties.status');

  headerComponent() {
    return StatusBoardHeaderComponent;
  }

  public warningTextWhenNoOptionsAvailable():Promise<string> {
    return Promise.resolve(this.I18n.t('js.boards.add_list_modal.warning.status'));
  }

  protected loadUncached():Observable<StatusResource[]> {
    return this
      .apiV3Service
      .statuses
      .get()
      .pipe(
        map((collection) => collection.elements),
      );
  }
}
