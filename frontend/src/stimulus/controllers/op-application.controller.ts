import { ControllerConstructor } from '@hotwired/stimulus/dist/types/core/controller';
import { ApplicationController } from 'stimulus-use';

export class OpApplicationController extends ApplicationController {
  static targets = ['dynamic'];

  private loaded = new Set<string>();

  dynamicTargetConnected(target:HTMLElement) {
    const controller = target.dataset.controller as string;

    if (!this.loaded.has(controller)) {
      this.loaded.add(controller);
      void import(/* webpackChunkName: "[request]" */`./dynamic/${controller}.controller`)
        .then((imported:{ default:ControllerConstructor }) => this.application.register(controller, imported.default))
        .catch((err:unknown) => {
          console.error('Failed to load dyanmic controller chunk %O: %O', controller, err);
        });
    }
  }
}
