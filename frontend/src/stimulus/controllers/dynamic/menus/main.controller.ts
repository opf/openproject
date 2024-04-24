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
    const targetLi = target.closest('li') as HTMLElement;

    this.toggleMenuState(this.rootTarget);
    this.toggleMenuState(targetLi);

    targetLi.querySelector<HTMLElement>('li > a, .tree-menu--title')?.focus();

    this.markActive(targetLi.dataset.name as string);
  }

  ascend(event:MouseEvent) {
    event.preventDefault();
    const target = event.target as HTMLElement;
    const parent = target.closest('li') as HTMLElement;

    this.toggleMenuState(parent);
    this.toggleMenuState(this.rootTarget);

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

  private toggleMenuState(item:HTMLElement) {
    item.classList.toggle('closed');
    item.classList.toggle('open');
  }
}
