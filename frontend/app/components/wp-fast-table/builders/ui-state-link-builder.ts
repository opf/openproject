import {KeepTabService} from 'core-components/wp-single-view-tabs/keep-tab/keep-tab.service';
import {StateService} from '@uirouter/core';

export const uiStateLinkClass = '__ui-state-link';
export const checkedClassName = '-checked';

export class UiStateLinkBuilder {

  constructor(public readonly $state:StateService,
              public readonly keepTab:KeepTabService) {
  }

  public linkToDetails(workPackageId:string, title:string, content:string) {
    return this.build(workPackageId, 'currentDetailsState', title, content);
  }

  public linkToShow(workPackageId:string, title:string, content:string) {
    return this.build(workPackageId, 'currentShowState', title, content);
  }

  private build(workPackageId:string, state:string, title:string, content:string) {
    let a = document.createElement('a');

    a.href = this.$state.href((this.keepTab as any)[state], {workPackageId: workPackageId});
    a.classList.add(uiStateLinkClass);
    a.dataset['workPackageId'] = workPackageId;
    a.dataset['wpState'] = state;

    a.setAttribute('title', title);
    a.textContent = content;

    return a;
  }
}
