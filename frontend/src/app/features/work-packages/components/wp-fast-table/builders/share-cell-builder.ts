import { Injector } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { QueryColumn } from '../../wp-query/query-column';
import { tdClassName } from './cell-builder';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { PrincipalRendererService } from 'core-app/shared/components/principal/principal-renderer.service';
import {
  WorkPackageShareModalComponent,
} from 'core-app/features/work-packages/components/wp-share-modal/wp-share.modal';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

export class ShareCellbuilder {
  @InjectField(IsolatedQuerySpace) isolatedQuerySpace:IsolatedQuerySpace;

  @InjectField(PrincipalRendererService) principalRenderer:PrincipalRendererService;

  @InjectField(OpModalService) opModalService:OpModalService;

  @InjectField(I18nService) I18n:I18nService;

  constructor(public readonly injector:Injector) {
  }

  public build(workPackage:WorkPackageResource, column:QueryColumn) {
    const td = document.createElement('td');
    td.classList.add(tdClassName, column.id);
    td.dataset.columnId = column.id;

    const relevantShares = this
      .isolatedQuerySpace
      .workPackageSharesCache
      .get(workPackage.id as string)
      .getValueOr([]);

    if (relevantShares.length === 0) {
      td.innerHTML = '-';
    } else {
      this
        .principalRenderer
        .renderAbbreviated(
          td,
          relevantShares.map((share) => share.principal),
        );

      td.setAttribute('title', this.I18n.t('js.work_packages.sharing.show_all_users'));
    }
    td.addEventListener('click', this.showShareModal.bind(this, workPackage));

    return td;
  }

  private showShareModal(workPackage:WorkPackageResource) {
    this.opModalService.show(WorkPackageShareModalComponent, 'global', { workPackage }, false, true);
  }
}
