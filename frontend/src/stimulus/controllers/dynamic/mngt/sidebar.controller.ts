import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['expandAllBtn', 'collapseAllBtn'];

  declare expandAllBtnTarget:    HTMLButtonElement;
  declare collapseAllBtnTarget:  HTMLButtonElement;
  declare hasExpandAllBtnTarget: boolean;
  declare hasCollapseAllBtnTarget: boolean;

  connect():void {
    this.updateActive();
    document.addEventListener('turbo:load', this.onTurboLoad);
    document.addEventListener('turbo:frame-load', this.onTurboLoad);
    this.element.addEventListener('click', this.onSidebarClick);
    const growSection = this.element.querySelector('.mngt-sidebar-section--grow');
    if (growSection) growSection.addEventListener('toggle', this.onFolderToggle, true);
    this.updateSpacesButtons();
  }

  disconnect():void {
    document.removeEventListener('turbo:load', this.onTurboLoad);
    document.removeEventListener('turbo:frame-load', this.onTurboLoad);
    this.element.removeEventListener('click', this.onSidebarClick);
    const growSection = this.element.querySelector('.mngt-sidebar-section--grow');
    if (growSection) growSection.removeEventListener('toggle', this.onFolderToggle, true);
  }

  expandAllSpaces(event: MouseEvent): void {
    event.preventDefault();
    this.getSpacesDetails().forEach((d) => { d.open = true; });
    this.updateSpacesButtons();
  }

  collapseAllSpaces(event: MouseEvent): void {
    event.preventDefault();
    this.getSpacesDetails().forEach((d) => { d.open = false; });
    this.updateSpacesButtons();
  }

  private readonly onFolderToggle = (): void => {
    this.updateSpacesButtons();
  };

  private readonly onTurboLoad = ():void => {
    this.updateActive();
  };

  private readonly onSidebarClick = (event: MouseEvent):void => {
    const link = (event.target as HTMLElement).closest<HTMLAnchorElement>('a[href]');
    if (!link) return;
    if (link.dataset.turboFrame || link.target || link.dataset.turbo === 'false') return;

    const href = link.getAttribute('href') ?? '';
    if (!href || href.startsWith('#') || /^https?:\/\//.test(href) || href.startsWith('mailto:')) return;

    const frame = document.getElementById('op-content-frame') as (HTMLElement & { src: string }) | null;
    if (!frame) return;

    event.preventDefault();
    frame.src = href;
  };

  private getSpacesDetails(): HTMLDetailsElement[] {
    const section = this.element.querySelector('.mngt-sidebar-section--grow');
    if (!section) return [];
    return Array.from(section.querySelectorAll<HTMLDetailsElement>('details.mngt-sidebar-group'));
  }

  private updateSpacesButtons(): void {
    if (!this.hasExpandAllBtnTarget || !this.hasCollapseAllBtnTarget) return;
    const details = this.getSpacesDetails();
    this.expandAllBtnTarget.disabled  = details.length === 0 || details.every((d) => d.open);
    this.collapseAllBtnTarget.disabled = details.length === 0 || details.every((d) => !d.open);
  }

  private updateActive():void {
    const path = window.location.pathname;
    this.element.querySelectorAll<HTMLElement>('.mngt-sidebar-item[href]').forEach((el) => {
      const href = el.getAttribute('href') as string;
      const active = path === href || path.startsWith(`${href}/`);
      el.classList.toggle('mngt-sidebar-item--active', active);
    });
  }
}
