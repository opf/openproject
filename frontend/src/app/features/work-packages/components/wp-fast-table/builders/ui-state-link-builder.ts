import { StateService } from '@uirouter/core';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';

export const uiStateLinkClass = '__ui-state-link';
export const checkedClassName = '-checked';

export class UiStateLinkBuilder {
  constructor(public readonly $state:StateService,
    public readonly keepTab:KeepTabService) {
  }

  public linkToDetails(workPackageId:string, title:string, content:string) {
    return this.build(workPackageId, 'split', title, content);
  }

  public linkToShow(workPackageId:string, title:string, content:string) {
    return this.build(workPackageId, 'show', title, content);
  }

  private build(workPackageId:string, state:'show'|'split', title:string, content:string) {
    const a = document.createElement('a');
    let tabState:string;
    let tabIdentifier:string;

    if (state === 'show') {
      tabState = 'work-packages.show.tabs';
      tabIdentifier = this.keepTab.currentShowTab;
    } else {
      tabState = 'work-packages.partitioned.list.details.tabs';
      tabIdentifier = this.keepTab.currentDetailsTab;
    }
    a.href = this.$state.href(
      tabState,
      {
        workPackageId,
        tabIdentifier,
      },
    );
    a.classList.add(uiStateLinkClass);
    a.dataset.workPackageId = workPackageId;
    a.dataset.wpState = state;

    a.setAttribute('title', title);
    a.textContent = content;

    return a;
  }
}
