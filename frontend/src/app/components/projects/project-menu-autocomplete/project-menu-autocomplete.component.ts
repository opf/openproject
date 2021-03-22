//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import {
  IAutocompleteItem,
  ILazyAutocompleterBridge
} from 'core-app/modules/autocompleter/lazyloaded/lazyloaded-autocompleter';
import { keyCodes } from 'core-app/modules/common/keyCodes.enum';
import { LinkHandling } from 'core-app/modules/common/link-handling/link-handling';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { HttpClient } from "@angular/common/http";
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, OnInit } from "@angular/core";
import { CurrentProjectService } from "core-components/projects/current-project.service";

export interface IProjectMenuEntry {
  id:number;
  name:string;
  identifier:string;
  parents:IProjectMenuEntry[];
  level:number;
}

export type ProjectAutocompleteItem = IAutocompleteItem<IProjectMenuEntry>;

export const projectMenuAutocompleteSelector = 'project-menu-autocomplete';

@Component({
  templateUrl: './project-menu-autocomplete.template.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: projectMenuAutocompleteSelector
})
export class ProjectMenuAutocompleteComponent extends ILazyAutocompleterBridge<IProjectMenuEntry> implements OnInit {
  public text:any;

  // The project dropdown menu
  public dropdownMenu:JQuery;
  // The project filter input
  public input:JQuery;
  // No results element
  public noResults:JQuery;

  // The result set for the instance, loaded only once
  public results:null|IProjectMenuEntry[] = null;

  private loaded = false;
  private $element:JQuery;


  constructor(protected PathHelper:PathHelperService,
              protected elementRef:ElementRef,
              protected http:HttpClient,
              protected cdRef:ChangeDetectorRef,
              protected I18n:I18nService,
              protected currentProject:CurrentProjectService) {
    super('projectMenuAutocomplete');

    this.text = {
      label: I18n.t('js.projects.autocompleter.label'),
      no_results: I18n.t('js.notice_no_principals_found'),
      loading: I18n.t('js.ajax.loading')
    };
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
    this.dropdownMenu = this.$element.parents('li.drop-down');
    this.input = this.$element.find('.project-menu-autocomplete--input');
    this.noResults = this.$element.find('.project-menu-autocomplete--no-results');

    this.dropdownMenu.on('opened', () => this.open());
    this.dropdownMenu.on('closed', () => this.close());
  }

  public close() {
    try {
      (this.input as any).projectMenuAutocomplete('destroy');
    } catch (e) {
      console.warn("Failed to destroy autocomplete: %O", e);
    }
    this.$element.find('.project-search-results').css('visibility', 'hidden');
  }

  public open() {
    this.$element.find('.project-search-results').css('visibility', 'visible');
    this.loadProjects().then((results:IProjectMenuEntry[]) => {
      const autocompleteValues = _.map(results, project => {
        return { label: project.name, render: 'match', object: project } as ProjectAutocompleteItem;
      });

      this.setup(this.input, autocompleteValues);
      this.addInputHandlers();
      this.addClickHandler();
      this.loaded = true;
      this.cdRef.detectChanges();

      this.scrollCurrentProjectIntoView();
    });
  }

  // Items per page to show before using lazy load
  // Please note that the max-height of the container is relevant here.
  public get maxItemsPerPage() {
    return 250;
  }

  onItemSelected(project:IProjectMenuEntry):void {
    window.location.href = this.projectLink(project.identifier);
  }

  onNoResultsFound(event:JQueryUI.AutocompleteEvent, ui:any):void {
    // Show the noResults span if we don't have any matches
    this.noResults.toggle(ui.content.length === 0);
  }

  public renderItem(item:ProjectAutocompleteItem, div:JQuery):void {
    const link = jQuery('<a>')
      .attr('href', this.projectLink(item.object.identifier))
      .text(item.label)
      .appendTo(div);

    // When in hierarchy, indent
    if (item.object.level > 0) {
      link
        .text(`» ${item.label}`)
        .css('padding-left', (4 + item.object.level * 16) + 'px');
    }

    // Highlight selected project
    if (item.object.identifier === this.currentProject.identifier) {
      div.addClass('selected');
    }
  }

  public projectLink(identifier:string) {
    const currentMenuItem = jQuery('meta[name="current_menu_item"]').attr('content');
    let url = this.PathHelper.projectPath(identifier);

    if (currentMenuItem) {
      url += '?jump=' + encodeURIComponent(currentMenuItem);
    }

    return url;
  }

  public get loadingText():string {
    if (this.loaded) {
      return '';
    } else {
      return this.text.loading;
    }
  }

  private loadProjects() {
    if (this.results !== null) {
      return Promise.resolve(this.results);
    }

    const url = this.PathHelper.projectLevelListPath();
    return this.http
      .get(url)
      .toPromise()
      .then((result:{ projects:any }) => {
        return this.results = this.augmentWithParents(result.projects);
      });
  }

  /**
   * Augment the level_list with the set of parents that belong to this project
   */
  public augmentWithParents(projects:IProjectMenuEntry[]) {
    const parents:IProjectMenuEntry[] = [];
    let currentLevel = -1;

    return projects.map((project) => {
      while (currentLevel >= project.level) {
        parents.pop();
        currentLevel--;
      }

      parents.push(project);
      currentLevel = project.level;
      project.parents = parents.slice(0, -1); // make sure to pass a clone

      return project;
    });
  }

  /**
   * Determines from the set of matched results, the elements we should render
   * (ie. including the parents of the elements)
   */
  protected augmentedResultSet(items:ProjectAutocompleteItem[], matched:ProjectAutocompleteItem[]) {
    const matches = matched.map(el => el.object.identifier);
    const matchedParents = _.flatten(matched.map(el => el.object.parents));

    const results:ProjectAutocompleteItem[] = [];

    items.forEach(el => {
      const identifier = el.object.identifier;
      let renderType:'disabled'|'match';

      if (matches.indexOf(identifier) >= 0) {
        renderType = 'match';
      } else if (_.find(matchedParents, e => e.identifier === identifier)) {
        renderType = 'disabled';
      } else {
        return;
      }

      results.push({
        label: el.label,
        object: el.object,
        render: renderType
      });
    });

    return results;
  }

  /**
   * Avoid closing the results when the input has lost focus.
   */
  protected addInputHandlers() {
    this.input.off('blur');

    this.input.keydown((evt:JQuery.TriggeredEvent) => {
      if (evt.which === keyCodes.ESCAPE) {
        this.input.val('');
        (this.input as any)[this.widgetName].call(this.input, 'search', '');
        return false;
      }

      return true;
    });
  }

  /**
   * When clicking an item with meta keys,
   * avoid its propagation.
   *
   */
  protected addClickHandler() {
    var touchMoved = false;
    this.$element
      .find('.project-menu-autocomplete--results')
      .on('click', '.ui-menu-item a', (evt:JQuery.TriggeredEvent) => {
        if (LinkHandling.isClickedWithModifier(evt)) {
          evt.stopImmediatePropagation();
        }

        return true;
      })

      // On iOS the click event doesn't get fired. So we need to listen to touch events and discard them if they they
      // are the beginning of some scrolling.
      .on('touchend', '.ui-menu-item a', function (evt:JQuery.TriggeredEvent) {
        if (!touchMoved) {
          window.location.href = (evt.target as HTMLAnchorElement).href;
        }
      }).on('touchmove', '.ui-menu-item a', function () {
        touchMoved = true;
      }).on('touchstart', '.ui-menu-item a', function () {
        touchMoved = false;
      });
  }

  protected setupParams(autocompleteValues:ProjectAutocompleteItem[]) {
    const params:any = super.setupParams(autocompleteValues);

    // Append to top-menu
    params.appendTo = '.project-menu-autocomplete--wrapper';
    params.classes = {
      'ui-autocomplete': '-inplace project-menu-autocomplete--results'
    };
    params.position = {
      of: '.project-menu-autocomplete--input-container'
    };

    return params;
  }

  private scrollCurrentProjectIntoView() {
    const currentProject:HTMLElement|null = document.querySelector('.ui-menu-item-wrapper.selected');

    // It can happen that no project is selected yet initially.
    if (!currentProject) {
      return;
    }

    const currentProjectHeight = currentProject.offsetHeight;
    const scrollableContainer = document.getElementsByClassName('project-menu-autocomplete--results')[0];

    // Scroll current project to top of the list and
    // substract half the container width again to center it vertically
    const scrollValue = currentProject.offsetTop -
      (scrollableContainer as HTMLElement).offsetHeight / 2 +
      currentProjectHeight / 2;

    // The top visible project shall be seen completely.
    // Otherwise there will be a scrolling effect when the user hovers over the project.
    scrollableContainer.scrollTop = (scrollValue % currentProjectHeight === 0) ?
      scrollValue :
      scrollValue - (scrollValue % currentProjectHeight);
  }
}

