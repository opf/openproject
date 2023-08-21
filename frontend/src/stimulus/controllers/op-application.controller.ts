import { ControllerConstructor } from '@hotwired/stimulus/dist/types/core/controller';
import { ApplicationController } from 'stimulus-use';

export class OpApplicationController extends ApplicationController {
  static targets = ['dynamic'];

  private loaded = new Set<string>();

  dynamicTargetConnected(target:HTMLElement) {
    const controller = target.dataset.controller as string;
    const path = this.derivePath(controller);

    if (!this.loaded.has(controller)) {
      this.loaded.add(controller);
      void import(/* webpackChunkName: "[request]" */`./dynamic/${path}.controller`)
        .then((imported:{ default:ControllerConstructor }) => this.application.register(controller, imported.default))
        .catch((err:unknown) => {
          console.error('Failed to load dyanmic controller chunk %O: %O', controller, err);
        });
    }
  }

  /**
   * Derive dynamic path from controller name.
   *
   * Stimlus conventions allow subdirectories to be used by double dashes.
   * We convert these to slashes for the dynamic import.
   *
   * https://stimulus.hotwired.dev/handbook/installing#controller-filenames-map-to-identifiers
   * @param controller
   * @private
   */
  private derivePath(controller:string):string {
    return controller.replace('--', '/');
  }
}
