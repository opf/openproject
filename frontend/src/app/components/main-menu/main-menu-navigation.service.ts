import {BehaviorSubject} from "rxjs";
import {filter, take} from "rxjs/operators";
import {Injectable} from "@angular/core";

@Injectable({ providedIn: 'root' })
export class MainMenuNavigationService {

  public navigationEvents$ = new BehaviorSubject<string>('');

  public onActivate(...names:string[]) {
    return this
      .navigationEvents$
      .pipe(
        filter(evt => names.indexOf(evt) !== -1),
        take(1)
      );
  }

  private recreateToggler() {
    let that = this;
    // rejigger the main-menu sub-menu functionality.
    jQuery("#main-menu .toggler").remove(); // remove the togglers so they're inserted properly later.

    var toggler = jQuery('<a class="toggler" href="#"><i class="icon6 icon-toggler icon-arrow-right3" aria-hidden="true"></i><span class="hidden-for-sighted"></span></a>')
      .on('click', function() {
        let target = jQuery(this);
        if (target.hasClass('toggler')) {

          // TODO: Instead of hiding the sidebar move sidebar's contents to submenus and cache it.
          jQuery('#sidebar').toggleClass('-hidden', true);

          jQuery(".menu_root li").removeClass('open')
          jQuery(".menu_root").removeClass('open').addClass('closed');

          let targetLi = target.closest('li')
          targetLi
            .addClass('open')
            .find('li > a:first, .tree-menu--title:first').first().focus();

          console.log("Activating " + targetLi.data('name'));
          that.navigationEvents$.next(targetLi.data('name'));
        }
        return false;
      });
    toggler.attr('title', I18n.t('js.project_menu_details'));

    return toggler;
  }

  private wrapMainItem() {
    var mainItems = jQuery('#main-menu li > a').not('ul ul a');

    mainItems.wrap((index:number) => {
      var item = mainItems[index];
      var elementId = item.id;

      var wrapperElement = jQuery('<div class="main-item-wrapper"/>')

      // inherit element id
      if (elementId) {
        wrapperElement.attr('id', elementId + '-wrapper')
      }

      return wrapperElement;
    });
  }

  register() {

    // Wrap main item
    this.wrapMainItem();

    // Scroll to the active item
    const selected = jQuery('.main-item-wrapper a.selected');
    if (selected.length > 0) {
      selected[0].scrollIntoView();
    }


    // Recreate toggler
    const toggler = this.recreateToggler();

    // Emit first active
    let active = jQuery('#main-menu .menu_root > li.open').data('name');
    let activeRoot = jQuery('#main-menu .menu_root.open > li').data('name');
    if (active || activeRoot) {
      this.navigationEvents$.next(active || activeRoot);
    }

    jQuery('#main-menu li:has(ul) .main-item-wrapper > a').not('ul ul a')
    // 1. unbind the current click functions
      .unbind('click')
      // 2. wrap each in a span that we'll use for the new click element
      .wrapInner('<span class="ellipsis"/>')
      // 3. reinsert the <span class="toggler"> so that it sits outside of the above
      .after(toggler);

    function navigateUp(this:any, event:any) {
      event.preventDefault();
      var target = jQuery(this);
      jQuery(target).parents('li').first().removeClass('open');
      jQuery(".menu_root").removeClass('closed').addClass('open');

      target.parents('li').first().find('.toggler').first().focus();

      // TODO: Instead of hiding the sidebar move sidebar's contents to submenus and cache it.
      jQuery('#sidebar').toggleClass('-hidden', false);
    }

    jQuery('#main-menu ul.main-menu--children').each(function(_i, child) {
      var title = jQuery(child).parents('li').find('.main-item-wrapper .menu-item--title').contents()[0].textContent;
      var parentURL = jQuery(child).parents('li').find('.main-item-wrapper > a').attr('href');
      var header = jQuery('<div class="main-menu--children-menu-header"></div>');
      var upLink = jQuery('<a class="main-menu--arrow-left-to-project" href="#"><i class="icon-arrow-left1" aria-hidden="true"></i></a>');
      var parentLink = jQuery('<a href="' + parentURL + '" class="main-menu--parent-node ellipsis">' + title + '</a>');
      upLink.attr('title', I18n.t('js.label_up'));
      upLink.on('click', navigateUp);
      header.append(upLink);
      header.append(parentLink);
      jQuery(child).before(header);
    });

    if (jQuery('.menu_root').hasClass('closed')) {
      // TODO: Instead of hiding the sidebar move sidebar's contents to submenus and cache it.
      jQuery('#sidebar').toggleClass('-hidden', true);
    }
  }

}
