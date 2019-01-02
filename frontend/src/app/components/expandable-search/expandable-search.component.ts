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

export const expandableSearchSelector = 'expandable-search';

@Component({
  selector: expandableSearchSelector,
  templateUrl: './expandable-search.component.html'
})

export class ExpandableSearchComponent implements OnDestroy {
  @ViewChild('inputEl') input:ElementRef;
  @ViewChild('btn') btn:ElementRef;

  public collapsed:boolean = true;
  public focused:boolean = false;
  public noResults = false;

  private $element:JQuery;
  private $input:JQuery;

  private unregisterGlobalListener:Function | undefined;

  constructor(readonly FocusHelper:FocusHelperService,
              readonly elementRef:ElementRef,
              readonly renderer:Renderer2,
              readonly I18n:I18nService,
              readonly PathHelperService:PathHelperService,
              readonly halResourceService:HalResourceService) {
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
    this.$input = jQuery(this.input.nativeElement);

    let selected = false;

    this.$input.autocomplete({
      delay: 250,
      autoFocus: false, // Accessibility!
      appendTo: '#top-menu',
      classes: {
        'ui-autocomplete': 'search-autocomplete--results'
      },
      position: {
        my: 'left top+10',
        at: 'left bottom'
      },
      source: (request:{ term:string }, response:Function) => {
        this.autocompleteWorkPackages(request.term).then((values) => {
          selected = false;
          response(values.map(wp => {
            return { workPackage: wp };
          }));
        });
      },
      select: (_evt:any, ui:any) => {
        selected = true;
        this.redirectToWp(ui.item.workPackage.id);
      },
      minLength: 0
    })
    .data('ui-autocomplete')._renderItem = (ul:JQuery, item:{workPackage:WorkPackageResource}) => {
      let workPackage = item.workPackage;
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
        )
        .appendTo(ul);
    };
  }

  // detect if click is outside or inside the element
  @HostListener('click', ['$event'])
  public handleClick(event:JQueryEventObject):void {
    event.stopPropagation();
    event.preventDefault();

    // If search is open, submit form when clicked on icon
    if (!this.collapsed && ContainHelpers.insideOrSelf(this.btn.nativeElement, event.target)) {
      this.submitNonEmptySearch();
    }

    if (this.collapsed) {
      this.collapsed = false;
      this.FocusHelper.focusElement(jQuery(this.input.nativeElement));
      this.registerOutsideClick();
    }
  }

  public closeWhenFocussedOutside() {
    ContainHelpers.whenOutside(this.elementRef.nativeElement, () => this.close());
    return false;
  }

  public redirectToWp(id:string) {
    window.location = this.PathHelperService.workPackagePath(id) as unknown as Location;
  }

  private registerOutsideClick() {
    this.unregisterGlobalListener = this.renderer.listen('document', 'click', () => {
      this.close();
    });
  }

  private close() {
    this.collapsed = true;
    this.searchValue = '';
    this.unregister();
  }

  private unregister() {
    if (this.unregisterGlobalListener) {
      this.unregisterGlobalListener();
      this.unregisterGlobalListener = undefined;
    }
  }

  private submitNonEmptySearch() {
    if (this.searchValue !== '') {
      jQuery(this.input.nativeElement)
        .closest('form')
        .submit();
    }
  }

  private get searchValue() {
    return this.input.nativeElement.value;
  }

  private set searchValue(val:string) {
    this.input.nativeElement.value = val;
  }

  ngOnDestroy():void {
    this.$input.autocomplete('destroy');
    this.unregister();
  }

  private autocompleteWorkPackages(query:string):Promise<WorkPackageResource[]> {
    this.$element.find('.ui-autocomplete--loading').show();
    let idOnly:boolean = false;

    if (query.match(/^#\d+$/)) {
      query = query.replace(/^#/, '');
      idOnly = true;
    }

    let href = this.PathHelperService.api.v3.wpBySubjectOrId(query, idOnly);

    return this.halResourceService
      .get<CollectionResource<WorkPackageResource>>(href)
      .toPromise()
      .then((collection) => {
        this.noResults = collection.count === 0;
        this.hideSpinner();
        return collection.elements || [];
      }).catch(() => {
        this.hideSpinner();
        return [];
      });
  }

  private hideSpinner():void {
    this.$element.find('.ui-autocomplete--loading').hide();
  }
}

DynamicBootstrapper.register({
  selector: expandableSearchSelector, cls: ExpandableSearchComponent
});
