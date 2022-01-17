import { Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';

@Component({
  selector: 'op-quick-add-pane',
  templateUrl: './quick-add-pane.component.html',
  styleUrls: ['./quick-add-pane.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class QuickAddPaneComponent implements OnInit {
  isEmpty = true;

  text = {
    empty_state: this.I18n.t('js.team_planner.quick_add.empty_state'),
  };

  image = {
    empty_state: imagePath('team-planner/quick-add-empty-state.svg'),
  };

  constructor(
    private I18n:I18nService,
  ) { }

  ngOnInit():void {
  }
}
