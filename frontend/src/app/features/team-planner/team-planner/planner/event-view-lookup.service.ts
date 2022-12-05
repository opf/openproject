import {
  EmbeddedViewRef,
  Injectable,
  OnDestroy,
  TemplateRef,
  ViewContainerRef,
} from '@angular/core';
import { debugLog } from 'core-app/shared/helpers/debug_output';

/**
 * View lookup service for injecting angular templates
 * as fullcalendar event content.
 *
 * Based on the suggestion from Daniel Goldsmith
 * in https://github.com/fullcalendar/fullcalendar-angular/issues/204
 *
 */
@Injectable()
export class EventViewLookupService implements OnDestroy {
  /** Active templates currently rendered */
  private readonly activeViews = new Map<string, EmbeddedViewRef<unknown>>();

  /** Remember detached views to be destroyed on destroyAll */
  private readonly detachedViews:EmbeddedViewRef<unknown>[] = [];

  constructor(private viewContainerRef:ViewContainerRef) {
  }

  /**
   * Gets the view for the given ID, or creates one if there isn't one
   * already. The template's context is set (or updated to, if the
   * view has already been created) the given context values.
   * @param template The template ref (get this from a @ViewChild of an
   * <ng-template>)
   * @param id The unique ID for this instance of the view. Use this so that
   * you don't keep around views for the same event.
   * @param context The available variables for the <ng-template>. For
   * example, if it looks like this: <ng-template let-localVar="value"> then
   * your context should be an object with a `value` key.
   */
  getView(
    template:TemplateRef<unknown>, id:string, context:unknown,
  ):EmbeddedViewRef<unknown> {
    let view = this.activeViews.get(id);
    if (view) {
      debugLog('Returning active view %O', id);
      view.detectChanges();
      return view;
    }

    // Create a new view and move to active
    debugLog('CREATING new view %O', id);
    view = this.viewContainerRef.createEmbeddedView(template, context);
    this.activeViews.set(id, view);
    view.detectChanges();

    return view;
  }

  ngOnDestroy():void {
    this.destroyAll();
  }

  /**
   * Call this method if all views need to be cleaned up. This will happen
   * when your parent component is destroyed (e.g., in ngOnDestroy),
   * but it may also be needed if you  are clearing just the area where the
   * views have been placed.
   */
  public destroyAll():void {
    debugLog('Destroying all views');

    Array
      .from(this.activeViews.values())
      .forEach(this.destroyView.bind(this));

    debugLog('Destroying %O active views', this.activeViews.size);
    this.activeViews.clear();

    this.destroyDetached();
  }

  /**
   * Call this method if you want to clean detached views.
   * This is safe to call outside of drag & drop operations.
   *
   */
  public destroyDetached():void {
    debugLog('Destroying %O detached views', this.detachedViews.length);

    while (this.detachedViews.length) {
      this.destroyView(this.detachedViews.pop() as EmbeddedViewRef<unknown>);
    }
  }

  /**
   * Mark a view to be destroyed.
   * It will only be destroyed once +destroyAll+ is called.
   *
   * Ensure that destroyAll is called when, e.g., refreshing the calendar.
   *
   * @param id View ID
   */
  public markForDestruction(id:string):void {
    const view = this.activeViews.get(id);
    if (!view) {
      return;
    }

    debugLog('Marking view %O to be destroyed', id);
    this.activeViews.delete(id);
    this.detachedViews.push(view);
  }

  private destroyView(view:EmbeddedViewRef<unknown>) {
    const index = this.viewContainerRef.indexOf(view);
    if (index !== -1) {
      this.viewContainerRef.remove(index);
    }

    view.destroy();
  }
}
