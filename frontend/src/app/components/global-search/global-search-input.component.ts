// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostListener,
  OnDestroy,
  Renderer2,
  ViewChild
} from '@angular/core';
import {ContainHelpers} from 'core-app/modules/common/focus/contain-helpers';
import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";
import {DynamicCssService} from "core-app/modules/common/dynamic-css/dynamic-css.service";
import {GlobalSearchService} from "core-components/global-search/global-search.service";
import {debounceTime, distinctUntilChanged} from "rxjs/operators";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {Subject, Subscription} from "rxjs";

export const globalSearchSelector = 'global-search-input';

@Component({
  selector: globalSearchSelector,
  templateUrl: './global-search-input.component.html'
})

export class GlobalSearchInputComponent implements OnDestroy {
  @ViewChild('inputEl') input:ElementRef;
  @ViewChild('btn') btn:ElementRef;

  public focused:boolean = false;
  public noResults = false;
  public searchTerm:string = '';

  private searchTermChanged:Subject<string> = new Subject<string>();

  private $element:JQuery;
  private $input:JQuery;

  private unregisterGlobalListener:Function | undefined;

  public text:{ [key:string]:string } = {
    all_projects: this.I18n.t('js.global_search.all_projects'),
    this_project: this.I18n.t('js.global_search.this_project'),
    this_project_and_all_descendants: this.I18n.t('js.global_search.this_project_and_all_descendants'),
    search: this.I18n.t('js.global_search.search') + ' here ...'
  };

  constructor(readonly FocusHelper:FocusHelperService,
              readonly elementRef:ElementRef,
              readonly renderer:Renderer2,
              readonly I18n:I18nService,
              readonly PathHelperService:PathHelperService,
              readonly halResourceService:HalResourceService,
              readonly dynamicCssService:DynamicCssService,
              readonly globalSearchService:GlobalSearchService,
              readonly cdRef:ChangeDetectorRef,
              readonly currentProjectService:CurrentProjectService) {
  }

  private projectScopeTypes = ['all_projects', 'this_project', 'this_project_and_all_descendants'];

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
    this.$input = jQuery(this.input.nativeElement);

    this.searchTermChanged
      .pipe(
        distinctUntilChanged(),
        debounceTime(250),
        untilComponentDestroyed(this)
      )
      .subscribe((searchTerm:string) => {
        this.searchTerm = searchTerm;

        // When there is already a Work Packages table in the search result, changing the search term should update
        // that table as you type and update the current URL displayed in the browser.
        if (this.globalSearchService.isAfterSearch() &&
            this.globalSearchService.currentTab === 'work_packages') {
          this.globalSearchService.searchTerm = searchTerm;
          window.history
                .replaceState({},
                         `${I18n.t('global_search.search')}: ${this.searchValue}`,
                              this.globalSearchService.searchPath());
        }

        this.cdRef.detectChanges();
      });

    this.globalSearchService.searchTerm$
      .pipe(
        distinctUntilChanged(),
        untilComponentDestroyed(this)
      )
      .subscribe((searchTerm:string) => {
        this.searchTerm = searchTerm;
        this.cdRef.detectChanges();
      });

    let selected = false;

    this.$input.autocomplete({
      delay: 250,
      autoFocus: true,
      appendTo: '#top-menu',
      classes: {
        'ui-autocomplete': 'search-autocomplete--results'
      },
      position: {
        my: 'left top+9',
        at: 'left bottom'
      },
      source: (request:{ term:string }, response:Function) => {
        this.autocompleteWorkPackages(request.term).then((values) => {
          selected = false;
          response(values.map(wp => {
            return { item: wp };
          }));
        });
      },
      focus: (_evt:any, _ui:any) => {
        // Stop propagation of this event to not overwrite the user's input.
        return false;
      },
      select: (_evt:any, ui:any) => {
        selected = true;

        switch (ui.item.item) {
          case 'all_projects': {
            this.globalSearchService.resultsHidden = true;
            this.globalSearchService.projectScope = 'all';
            this.submitNonEmptySearch(true);
            break;
          }
          case 'this_project': {
            this.globalSearchService.projectScope = 'current_project';
            this.submitNonEmptySearch();
            break;
          }
          case 'this_project_and_all_descendants': {
            this.globalSearchService.projectScope = '';
            this.submitNonEmptySearch();
            break;
          }
          default: {
            const workPackage = ui.item.item;
            this.redirectToWp(workPackage.id);
          }
        }
        // Stop propagation of this event to not overwrite the user's input.
        return false;
      },
      minLength: 1
    })
    .data('ui-autocomplete')._renderItem = (ul:JQuery, item:{item:string|WorkPackageResource}) => {
      if (_.includes(this.projectScopeTypes, item.item)) {
        return this.renderProjectScopeItem(item.item as string).appendTo(ul);
      } else {
        return this.renderWorkPackageItem(item.item as WorkPackageResource).appendTo(ul);
      }
    };

    this.$input.on('focus', () => {
      if (this.searchValue.length > 0) {
        this.$input.autocomplete('search', this.searchValue);
      }
    });
  }

  // detect if click is outside or inside the element
  @HostListener('click', ['$event'])
  public handleClick(event:JQueryEventObject):void {
    event.stopPropagation();
    event.preventDefault();

    if (ContainHelpers.insideOrSelf(this.btn.nativeElement, event.target)) {
      this.submitNonEmptySearch();
    }
  }

  public redirectToWp(id:string) {
    window.location = this.PathHelperService.workPackagePath(id) as unknown as Location;
  }

  private unregister() {
    if (this.unregisterGlobalListener) {
      this.unregisterGlobalListener();
      this.unregisterGlobalListener = undefined;
    }
  }

  public inputChange(searchTerm:string):void {
    this.searchTermChanged.next(searchTerm);
  }

  public submitNonEmptySearch(forcePageLoad:boolean = false) {
    this.globalSearchService.searchTerm = this.searchValue;
    if (this.searchValue !== '') {
      // Work package results can update without page reload.
      if (!forcePageLoad &&
          this.globalSearchService.isAfterSearch() &&
          this.globalSearchService.currentTab === 'work_packages') {
        return;
      }

      this.globalSearchService.submitSearch();
    }
  }

  private get searchValue() {
    return this.input.nativeElement.value;
  }

  ngOnDestroy():void {
    this.$input.autocomplete('destroy');
    this.unregister();
  }

  private autocompleteWorkPackages(query:string):Promise<(WorkPackageResource|string)[]> {
    this.dynamicCssService.requireHighlighting();

    this.$element.find('.ui-autocomplete--loading').show();
    let idOnly:boolean = false;

    if (query.match(/^#\d+$/)) {
      query = query.replace(/^#/, '');
      idOnly = true;
    }

    let href:string = this.PathHelperService.api.v3.wpBySubjectOrId(query, idOnly);

    let suggestions:(string|WorkPackageResource)[] = [];

    if (this.currentProjectService.path) {
      suggestions.push('this_project_and_all_descendants');
      suggestions.push('this_project');
    }

    suggestions.push('all_projects');

    return this.halResourceService
      .get<CollectionResource<WorkPackageResource>>(href)
      .toPromise()
      .then((collection) => {
        this.noResults = collection.count === 0;
        this.hideSpinner();
        return suggestions.concat(collection.elements);
      }).catch(() => {
        this.hideSpinner();
        return suggestions;
      });
  }

  private hideSpinner():void {
    this.$element.find('.ui-autocomplete--loading').hide();
  }

  private renderProjectScopeItem(scope:string):JQuery {
    return jQuery("<li>")
      .attr('data-value', scope)
      .attr('tabindex', -1)
      .append(
        jQuery('<div>')
          .addClass( 'ui-menu-item-wrapper')
          .append(
            jQuery('<span>')
              .addClass('search-autocomplete--search-term')
              .append(this.searchValue)
          ).append(
            jQuery('<span>')
              .addClass('search-autocomplete--project-scope')
              .append(`${this.text[scope]} ↵`)
          )
      );
  }

  private renderWorkPackageItem(workPackage:WorkPackageResource) {
    return jQuery("<li>")
      .attr('data-value', workPackage.id)
      .attr('tabindex', -1)
      .append(
        jQuery('<div>')
          .addClass( 'ui-menu-item-wrapper')
          .append(
            jQuery('<span>')
              .addClass('search-autocomplete--wp-id')
              .addClass(`__hl_dot_status_${workPackage.status.idFromLink}`)
              .attr('title', workPackage.status.name)
              .append(`#${workPackage.id}`)
          )
          .append(
            jQuery('<span>')
              .addClass('search-autocomplete--subject')
              .append(` ${workPackage.subject}`)
          )
      );
  }

  public resize() {
    jQuery(this.input.nativeElement).toggleClass('-expanded');
    jQuery('.top-menu-search--button').toggleClass('-input-focused');
  }
}

DynamicBootstrapper.register({
  selector: globalSearchSelector, cls: GlobalSearchInputComponent
});
