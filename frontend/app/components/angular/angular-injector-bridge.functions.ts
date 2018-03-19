/**
 * Returns the currently bootstrapped injector from the application.
 * Not applicable until after the application bootstrapping is done.
 */

/**
 *
 * @returns {any | angular.auto.IInjectorService}
 * @deprecated Pass ng2 injector to constructor instead
 */
export function $currentInjector() {
    return (window as any).ngInjector || angular.element(document.body).injector();
  }

/**
 *
 * @param {string} dep
 * @returns {any}
 * @deprecated Pass ng2 injector to constructor instead
 */
export function $injectNow(dep:string) {
    return $currentInjector().get(dep);
  }

  /**
   * Detects desired injections from `target.$inject = [...]` definitions
   * analogous to how angular does its DI, only that we're not registering the
   * factory.
   *
   * @param injectable The target to inject into
   * @deprecated Pass ng2 injector to constructor instead
   */
  export function injectorBridge(injectable:any) {
    let $injector = $currentInjector();
    $injectFields(injectable, ...$injector.annotate(injectable.constructor));
  }
  /**
   * Inject specified field into the target.
   * Use when `Constructor.$inject` isn't an option, e.g., due to class inerheritance.
   *
   * @param target The target to inject into
   * @param dependencies A set of dependencies to inject
   * @deprecated Pass ng2 injector to constructor instead
   */
  export function $injectFields(target:any, ...dependencies:string[]) {
    let $injector = $currentInjector();
    dependencies.forEach((dep:string) => {
      target[dep] = $injector.get(dep);
    });
  }


