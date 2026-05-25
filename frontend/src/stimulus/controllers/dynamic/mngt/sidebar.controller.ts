import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect():void {
    this.updateActive();
    document.addEventListener('turbo:load', this.onTurboLoad);
    document.addEventListener('turbo:frame-load', this.onTurboLoad);
    this.element.addEventListener('click', this.onSidebarClick);
  }

  disconnect():void {
    document.removeEventListener('turbo:load', this.onTurboLoad);
    document.removeEventListener('turbo:frame-load', this.onTurboLoad);
    this.element.removeEventListener('click', this.onSidebarClick);
  }

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

  private updateActive():void {
    const path = window.location.pathname;
    this.element.querySelectorAll<HTMLElement>('.mngt-sidebar-item[href]').forEach((el) => {
      const href = el.getAttribute('href') as string;
      const active = path === href || path.startsWith(`${href}/`);
      el.classList.toggle('mngt-sidebar-item--active', active);
    });
  }
}
