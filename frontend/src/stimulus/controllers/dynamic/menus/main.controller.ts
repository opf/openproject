import { Controller } from '@hotwired/stimulus';
import { MainMenuNavigationService } from 'core-app/core/main-menu/main-menu-navigation.service';

export default class MainMenuController extends Controller {
  static targets = [
    'sidebar',
    'root',
    'item',
  ];

  declare readonly sidebarTarget:HTMLElement;
  declare readonly rootTarget:HTMLElement;
  declare readonly itemTargets:HTMLElement[];

  initialize() {
    if (this.rootTarget.classList.contains('closed')) {
      this.sidebarTarget.classList.add('-hidden');
    }

    const active = this.getActiveMenuName();
    if (active) {
      this.markActive(active);
    }
  }

  descend(event:MouseEvent) {
    const target = event.target as HTMLElement;
    this.sidebarTarget.classList.add('-hidden');
    this.rootTarget.classList.remove('open');
    this.rootTarget.classList.add('closed');

    // TODO targets
    this.rootTarget
      .querySelectorAll<HTMLElement>('li')
      .forEach((item) => item.classList.remove('open'));

    const targetLi = target.closest('li') as HTMLElement;
    targetLi.classList.add('open');
    targetLi.querySelector<HTMLElement>('li > a, .tree-menu--title')?.focus();

    this.markActive(targetLi.dataset.name as string);
  }

  ascend(event:MouseEvent) {
    event.preventDefault();
    const target = event.target as HTMLElement;

    this.rootTarget.classList.remove('closed');
    this.rootTarget.classList.add('open');

    const parent = target.closest('li') as HTMLElement;
    parent.classList.remove('open');
    parent.querySelector<HTMLElement>('.toggler')?.focus();

    this.sidebarTarget.classList.remove('-hidden');
  }

  private getActiveMenuName():string|undefined {
    const activeItem = this.itemTargets.find((el) => el.classList.contains('open'));
    const activeRoot = this.rootTarget.querySelector('li');
    return (activeItem || activeRoot)?.dataset.name;
  }

  private markActive(active:string):void {
    void window.OpenProject.getPluginContext()
      .then((pluginContext) => pluginContext.injector.get(MainMenuNavigationService))
      .then((service) => service.navigationEvents$.next(active));
  }
}
