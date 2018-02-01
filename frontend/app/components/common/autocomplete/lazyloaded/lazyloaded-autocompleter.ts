import * as Fuse from 'fuse.js';
import {timeOutput} from '../../../../helpers/debug_output';

export interface IAutocompleteItem<T> {
  label:string;
  render:'match' | 'disabled';
  object:T;
}

export abstract class ILazyAutocompleterBridge<T> {
  // Current page the autocompleter is on
  public currentPage:number;

  // Input autocomplete element
  public input:JQuery;

  // Fuzzy instance for the results
  public fuseInstance:any;

  public constructor(public widgetName:string) {
    LazyLoadedAutocompleter.register(widgetName, this);
  }

  /**
   * Return the maximum number of items to render in this page.
   * Note that for this value, the container must be setup that a scrollbar exists.
   * @returns {number}
   */
  public abstract get maxItemsPerPage():number;

  /**
   * Handler function for when an active item was selected through the autocompleter
   * @param {T} item
   */
  public abstract onItemSelected(item:T):void;

  /**
   *  Handler function for when no results were matched through the search term.
   * @param {JQueryUI.AutocompleteEvent} event
   * @param {JQueryUI.AutocompleteUIParams} ui
   */
  public abstract onNoResultsFound(event:JQueryUI.AutocompleteEvent, ui:any):void;

  /**
   * Customize the rendering of an inner item element.
   *
   * @param {IAutocompleteItem} item
   * @param {JQuery} div
   */
  public renderItem(item:IAutocompleteItem<T>, div:JQuery):void {
    div.text(item.label);
  }

  /**
   * Returns the elements matched by the fuzzy search
   */
  private fuzzySearch(items:IAutocompleteItem<T>[], term:string) {
    if (term === '') {
      return items;
    }

    return this.fuseInstance.search(term) as any;
  }

  /**
   * Allows to augment the set of matched items (e.g., to add hierarchy).
   * @param {IAutocompleteItem<T>[]} items
   * @param {IAutocompleteItem<T>[]} matched
   * @returns {IAutocompleteItem<T>[]}
   */
  protected augmentedResultSet(items:IAutocompleteItem<T>[], matched:IAutocompleteItem<T>[]) {
    // By default, set all to match
    const results:IAutocompleteItem<T>[] = [];

    matched.forEach(el => {
      results.push({
        label: el.label,
        object: el.object,
        render: 'match'
      } as IAutocompleteItem<T>);
    });

    return results;
  }

  public setup(input:JQuery, items:IAutocompleteItem<T>[]) {
    this.currentPage = 0;
    this.input = input;
    this.input[this.widgetName].call(this.input, this.setupParams(items));
    const options = {
      shouldSort: true,
      tokenize: false,
      threshold: 0.2,
      location: 0,
      distance: 100,
      maxPatternLength: 16,
      minMatchCharLength: 2,
      keys: ['label']
    };

    this.fuseInstance = new Fuse(items, options);
  }

  protected setupParams(autocompleteValues:IAutocompleteItem<T>[]) {
    const ctrl = this;

    return {
      delay: 50,
      source: function (request:any, response:any) {
        const fuzzyResults = ctrl.fuzzySearch(autocompleteValues, request.term);
        response(ctrl.augmentedResultSet(autocompleteValues, fuzzyResults));
      },
      select: (ul:any, selected:{ item:IAutocompleteItem<T> }) => {
        if (selected.item.render === 'match') {
          ctrl.onItemSelected(selected.item.object);
        }
      },
      create: () => ctrl.input.focus(),
      response: (event:JQueryUI.AutocompleteEvent, ui:JQueryUI.AutocompleteUIParams) => {
        ctrl.onNoResultsFound(event, ui);
      },
      autoFocus: true,
      minLength: 0
    };
  }
}

export namespace LazyLoadedAutocompleter {

  /**
   * Returns whether the scrollbar is at a place where we should display additional elements
   * @param ul
   */
  function isScrollbarBottom(container:JQuery) {
    var height = container.outerHeight();
    var scrollHeight = container[0].scrollHeight;
    var scrollTop = container.scrollTop();
    return scrollTop >= (scrollHeight - height);
  }

  export function register<T>(name:string, ctrl:ILazyAutocompleterBridge<T>) {
    jQuery.widget(`custom.${name}`, jQuery.ui.autocomplete, {
      _create: function (this:any) {
        ctrl.currentPage = 0;
        this._super();
        this.widget().menu('option', 'items', '> .ui-matched-item');
        this._search('');
      },

      _renderMenu: function (this:any, ul:HTMLElement, items:IAutocompleteItem<T>[]) {
        //remove scroll event to prevent attaching multiple scroll events to one container element
        jQuery(ul).unbind('scroll');

        this._renderLazyMenu(ul, items);
      },

      // Rener the menu for the current page
      _renderMenuPage(this:any, ul:JQuery, items:IAutocompleteItem<T>[], page:number|null = null) {
        let widget = this;
        let rendered:number = items.length;
        let pageElements = items;
        let max = ctrl.maxItemsPerPage;
        if (page !== null) {
          pageElements = items.slice(page * max, (page * max) + max);
          rendered = Math.min(items.length, (page * max) + max);
        }

        // Insert elements of this page
        jQuery.each(pageElements, function (index, item) {
          widget._renderItemData(ul, item);
        });

        // Ensure scrollbar is shown when more results exist
        ul.css('height', 'auto');
        if (rendered < items.length) {
          const maxHeight = document.body.offsetHeight * 0.55;
          const shownHeight = rendered * 32;

          if (shownHeight < maxHeight) {
            ul.css('height', shownHeight - 50);
          }
        }
      },

      /**
       * Return the number of (lazy) pages for the curent set of results
       * @param {IAutocompleteItem[]} items
       * @returns {number}
       */
      _pages(items:IAutocompleteItem<T>[]):number {
        return Math.ceil(items.length / ctrl.maxItemsPerPage);
      },

      _repositionMenu: function (this:any, container:JQuery) {
        const widget = this;
        const menu = widget.menu;

        menu.refresh();

        // Call ui's own resize
        widget._resizeMenu();

        container.position(jQuery.extend({of: widget.element}, widget.options.position));
        if (widget.options.autoFocus) {
          menu.next(new jQuery.Event('mouseover'));
        }
      },

      _resizeMenu: function () {
        var ul = this.menu.element;
        ul.outerWidth(this.element.outerWidth());
      },

      _renderItem: function (this:any, ul:JQuery, item:IAutocompleteItem<T>) {
        const term = this.element.val();
        const disabled = item.render === 'disabled';
        const div = jQuery('<div>').addClass('ui-menu-item-wrapper');

        ctrl.renderItem(item, div);

        const element = jQuery('<li>')
          .toggleClass('ui-state-disabled', disabled)
          .toggleClass('ui-matched-item', !disabled)
          .append(div)
          .appendTo(ul);

        if (term !== '') {
          element.mark(term, {className: 'ui-autocomplete-match'});
        }

        return element;
      },

      _renderLazyMenu: function (this:any, ul:Element, items:IAutocompleteItem<T>[]) {
        const widget = this;
        const container = jQuery(ul);
        const pages = this._pages(items);

        if (pages <= 1) {
          return widget._renderMenuPage(ul, items);
        }

        widget._renderMenuPage(ul, items, 0);

        container.scroll(function () {
          if (isScrollbarBottom(container)) {
            if (++ctrl.currentPage >= pages) {
              return;
            }

            // Render the current menu page
            widget._renderMenuPage(ul, items, ctrl.currentPage);

            // Refresh the menu
            widget._repositionMenu(ul);
          }
        });
      }
    });
  }
}
