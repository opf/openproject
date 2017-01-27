export const uiStateLinkClass = '__ui-state-link';

export class UiStateLinkBuilder {

  public static linkToDetails(workPackageId:string, title:string, content:string) {
    return this.build(workPackageId, 'currentDetailsState', title, content);
  }

  public static linkToShow(workPackageId:string, title:string, content:string) {
    return this.build(workPackageId, 'currentShowState', title, content);
  }

  private static build(workPackageId:string, state:string, title:string, content:string) {
    let a = document.createElement('a');

    a.classList.add(uiStateLinkClass);
    a.dataset['workPackageId'] = workPackageId;
    a.dataset['wpState'] = state;

    a.setAttribute('title', title);
    a.textContent = content;

    return a;
  }
}
