import { ControllerConstructor } from '@hotwired/stimulus/dist/types/core/controller';
import { Application } from '@hotwired/stimulus';

export type DynamicControllerLoader = () => Promise<{ default:ControllerConstructor }>;

export class OpenProjectStimulusApplication extends Application {
  /** A map of controllers that have been preregistered. */
  static controllers = new Map<string, ControllerConstructor>();

  /** A map of a dynamic controller loader to load when the controller name is found */
  static dynamicImports = new Map<string, DynamicControllerLoader>();

  /**
   * Register a controller to be used in the application,
   * allowing it to be registered before the Stimulus application is being initialized.
   *
   * This is useful for plugins that execute code before we call setup.ts
   *
   * @param name the name/identifier of the controller
   * @param controller the controller class
   */
  static preregister(name:string, controller:ControllerConstructor) {
    this.controllers.set(name, controller);
  }

  /**
   * Register a dynamic controller to be imported using the given path,
   * allowing it to be defined somewhere else than within the dynamic/ subfolder.
   *
   * This is useful for plugins that want to define new dynamic controllers.
   * How to use this: In your plugin's main.ts, call this
   * @example
   * OpenProjectStimulusApplication.preregisterDynamic(
   *   'test',
   *   () => import('./test.controller')
   * );
   * ```
   *
   * @param name the name/identifier of the controller
   * @param loader A callback to provide the controller asynchronously.
   */
  static preregisterDynamic(name:string, loader:DynamicControllerLoader) {
    this.dynamicImports.set(name, loader);
  }

  async start():Promise<void> {
    this.preregisteredControllers.forEach((controller, name) => {
      this.register(name, controller);
    });

    await super.start();
  }

  get preregisteredControllers() {
    return OpenProjectStimulusApplication.controllers;
  }
}
