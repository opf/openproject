import { Controller } from '@hotwired/stimulus';
import { OpenProjectPluginContext } from 'core-app/features/plugins/plugin-context';

export default class extends Controller {
  async connect():Promise<void> {
    const context = await window.OpenProject.pluginContext.valuesPromise() as OpenProjectPluginContext;
    context.bootstrap(this.element as unknown as HTMLElement);
  }
}
