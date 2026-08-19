import { ControllerConstructor } from '@hotwired/stimulus/dist/types/core/controller';
import { ApplicationController } from 'stimulus-use';
import { AttributeObserver } from '@hotwired/stimulus';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { OpenProjectStimulusApplication } from 'core-stimulus/openproject-stimulus-application';

export class OpApplicationController extends ApplicationController {
  private loaded = new Set<string>();

  private controllerObserver:AttributeObserver;

  connect() {
    super.connect();
    this.controllerObserver = new AttributeObserver(
      this.element,
      'data-controller',
      {
        elementMatchedAttribute: (element:HTMLElement, _) => this.controllerAttributeFound(element),
      },
    );

    this.controllerObserver.start();
  }

  disconnect() {
    this.controllerObserver.stop();
  }

  controllerAttributeFound(target:HTMLElement) {
    const controllers = target.dataset.controller!.split(' ');
    const registered = this.application.router.modules.map((module) => module.definition.identifier);

    controllers.forEach((controller) => {
      if (!registered.includes(controller) && !this.loaded.has(controller)) {
        debugLog(`Loading controller ${controller}`);
        this.loaded.add(controller);

        void this
          .importController(controller)
          .then((clazz) => {
            if (clazz) {
              this.application.register(controller, clazz);
            }
          });
      }
    });
  }

  private async importController(controller:string):Promise<ControllerConstructor|null> {
    try {
      const imported = await this.fetchDynamicController(controller);
      return imported.default;
    } catch (err) {
      console.error('Failed to load dynamic controller chunk %O: %O', controller, err);
      return null;
    }
  }

  private async fetchDynamicController(controller:string) {
    if (OpenProjectStimulusApplication.dynamicImports.has(controller)) {
      return OpenProjectStimulusApplication.dynamicImports.get(controller)!();
    }

    // Default: Try to load the controller from dynamic/ subfolder.
    const path = this.derivePath(controller);
    return await import(`./dynamic/${path}.controller.ts`) as Promise<{
      default:ControllerConstructor
    }>;
  }

  /**
   * Derive dynamic path from controller name.
   *
   * Stimulus conventions allow subdirectories to be used by double dashes.
   * We convert these to slashes for the dynamic import.
   *
   * https://stimulus.hotwired.dev/handbook/installing#controller-filenames-map-to-identifiers
   * @param controller
   * @private
   */
  private derivePath(controller:string):string {
    return controller.replace(/--/g, '/');
  }
}
