import { Injector } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { QueryColumn } from '../../wp-query/query-column';
import { tdClassName } from './cell-builder';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { PrincipalRendererService } from 'core-app/shared/components/principal/principal-renderer.service';
import {
  WorkPackageShareModalComponent,
} from 'core-app/features/work-packages/components/wp-share-modal/wp-share.modal';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

export class ShareCellbuilder {
  @LazyInject(IsolatedQuerySpace) isolatedQuerySpace:IsolatedQuerySpace;

  @LazyInject(PrincipalRendererService) principalRenderer:PrincipalRendererService;

  @LazyInject(OpModalService) opModalService:OpModalService;

  @LazyInject(I18nService) I18n:I18nService;

  constructor(public readonly injector:Injector) {
  }

  public build(workPackage:WorkPackageResource, column:QueryColumn) {
    const td = document.createElement('td');
    td.classList.add(tdClassName, column.id);
    td.dataset.columnId = column.id;

    const relevantShares = this
      .isolatedQuerySpace
      .workPackageSharesCache
      .get(workPackage.id!)
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
