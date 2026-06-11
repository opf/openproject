import { Controller } from '@hotwired/stimulus';
import { MainMenuToggleService } from 'core-app/core/main-menu/main-menu-toggle.service';
import type { OpenProjectPluginContext } from 'core-app/features/plugins/plugin-context';
import { useServices } from 'core-stimulus/mixins/use-services';

export default class MainToggleController extends Controller {
  declare pluginContext:Promise<OpenProjectPluginContext>;

  mainMenuService:MainMenuToggleService|undefined;

  initialize() {
    useServices(this);
  }

  servicesConnected() {
    void this.connectMenuService();
  }

  disconnect() {
    this.mainMenuService = undefined;
  }

  toggleNavigation(e:Event) {
    this.mainMenuService?.toggleNavigation(e);
  }

  private async connectMenuService() {
    try {
      const { injector } = await this.pluginContext;
      this.mainMenuService = injector.get(MainMenuToggleService);
      this.mainMenuService.initializeMenu();
    } catch {
      // Keep swallowing injector failures, as the previous chain did — the
      // toggle then stays inert instead of erroring on every page.
    }
  }
}
