import {
  EmbeddedViewRef,
  Injectable,
  OnDestroy,
  TemplateRef,
  ViewContainerRef,
} from '@angular/core';

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
  private readonly views = new Map<string, EmbeddedViewRef<unknown>>();

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
   * @param comparator If you're re-rendering the same view and the context
   * hasn't changed, then performance is a lot better if we just return the
   * original view rather than destroying and re-creating the view.
   * Optionally pass this function to return true when the views should be
   * re-used.
   */
  getView(
    template:TemplateRef<unknown>, id:string, context:unknown,
    comparator?:(v1:unknown, v2:unknown) => boolean,
  ):EmbeddedViewRef<unknown> {
    let view = this.views.get(id);
    if (view) {
      if (comparator && comparator(view.context, context)) {
        // Nothing changed -- no need to re-render the component.
        view.markForCheck();
        return view;
      }

      // The performance would be better if we didn't need to destroy
      // the view here... but just updating the context and checking
      // changes doesn't work.
      this.destroyView(id);
    }

    view = this.viewContainerRef.createEmbeddedView(template, context);
    this.views.set(id, view);
    view.detectChanges();

    return view;
  }

  /**
   * Generates a view for the given template and returns the root DOM node(s)
   * for the view, which can be returned from an eventContent call.
   * @param template The template ref (get this from a @ViewChild of an
   * <ng-template>)
   * @param id The unique ID for this instance of the view. Use this so that
   * you don't keep around views for the same event.
   * @param context The available variables for the <ng-template>. For
   * example, if it looks like this: <ng-template let-localVar="value"> then
   * your context should be an object with a `value` key.
   * @param comparator If you're re-rendering the same view and the context
   * hasn't changed, then performance is a lot better if we just return the
   * original view rather than destroying and re-creating the view.
   * Optionally pass this function to return true when the views should be
   * re-used.
   */
  getTemplateRootNodes(
    template:TemplateRef<unknown>,
    id:string,
    context:unknown,
    comparator?:(v1:unknown, v2:unknown) => boolean,
  ):unknown[] {
    return this.getView(template, id, context, comparator).rootNodes;
  }

  hasView(id:string):boolean {
    return this.views.has(id);
  }

  /**
   * Marks the given view (or all views) as needing change detection.
   * Call `detectChanges` on your component if you need to run change
   * detection synchronously; normally Angular handles that.
   */
  markForCheck(id?:string):void {
    if (id) {
      this.views.get(id)?.markForCheck();
    } else {
      // eslint-disable-next-line no-restricted-syntax
      for (const view of this.views.values()) {
        view.markForCheck();
      }
    }
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
    // eslint-disable-next-line no-restricted-syntax
    for (const view of this.views.values()) {
      view.destroy();
    }
    this.views.clear();
  }

  public destroyView(id:string):void {
    const view = this.views.get(id);
    if (view) {
      const index = this.viewContainerRef.indexOf(view);
      if (index !== -1) {
        this.viewContainerRef.remove(index);
      }
      view.destroy();
      this.views.delete(id);
    }
  }
}
