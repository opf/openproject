import { Component, ChangeDetectionStrategy } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { videoPath } from 'core-app/shared/helpers/videos/path-helper';

@Component({
  selector: 'op-share-upsale',
  templateUrl: './share-upsale.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ShareUpsaleComponent {
  video = videoPath('sharing/share-work-package.mp4');

  text = {
    title: this.I18n.t('js.work_packages.sharing.title'),
    description: this.I18n.t('js.work_packages.sharing.upsale.description'),
  };

  constructor(
    readonly I18n:I18nService,
  ) { }
}
