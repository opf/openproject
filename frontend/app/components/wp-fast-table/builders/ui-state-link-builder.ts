import {injectorBridge} from '../../angular/angular-injector-bridge.functions';
import {KeepTabService} from '../../wp-panels/keep-tab/keep-tab.service';
export const uiStateLinkClass = '__ui-state-link';
export const checkedClassName = '-checked';

export class UiStateLinkBuilder {
  // Injected dependencies
  public $state:ng.ui.IStateService;
  public keepTab:KeepTabService;

  constructor() {
    injectorBridge(this);
  }

  public linkToDetails(workPackageId:string, title:string, content:string) {
    return this.build(workPackageId, 'currentDetailsState', title, content);
  }

  public linkToShow(workPackageId:string, title:string, content:string) {
    return this.build(workPackageId, 'currentShowState', title, content);
  }

  private build(workPackageId:string, state:string, title:string, content:string) {
    let a = document.createElement('a');

    a.href = this.$state.href((this.keepTab as any)[state], { workPackageId: workPackageId });
    a.classList.add(uiStateLinkClass);
    a.dataset['workPackageId'] = workPackageId;
    a.dataset['wpState'] = state;

    a.setAttribute('title', title);
    a.textContent = content;

    return a;
  }
}

UiStateLinkBuilder.$inject = ['$state', 'keepTab'];
