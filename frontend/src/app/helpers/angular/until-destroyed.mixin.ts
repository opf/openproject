import {OnDestroyMixin, untilComponentDestroyed} from "@w11k/ngx-componentdestroyed";
import {OnDestroy} from "@angular/core";
import {Observable} from "rxjs";

/**
 * Mixin function to provide access to observable and flags
 * whether this component has been destroyed.
 *
 * Use for rxjs with .pipe(this.untilDestroyed)
 */
export class UntilDestroyedMixin extends OnDestroyMixin implements OnDestroy {
  public componentDestroyed = false;

  ngOnDestroy():void {
    this.componentDestroyed = true;
    super.ngOnDestroy();
  }

  /**
   * Helper function to access `untilComponentDestroyed`
   */
  protected untilDestroyed<T>():(source:Observable<T>) => Observable<T> {
    return untilComponentDestroyed(this);
  }
}