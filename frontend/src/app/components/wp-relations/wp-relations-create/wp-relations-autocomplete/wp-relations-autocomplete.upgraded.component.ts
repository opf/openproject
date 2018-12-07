//-- copyright
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
//++

import {Component, ElementRef, EventEmitter, Inject, Input, OnDestroy, OnInit, Output} from '@angular/core';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {LoadingIndicatorService} from 'core-app/modules/common/loading-indicator/loading-indicator.service';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';

@Component({
  selector: 'wp-relations-autocomplete-upgraded',
  templateUrl: './wp-relations-autocomplete.upgraded.html'
})
export class WpRelationsAutocompleteComponent implements OnInit, OnDestroy {
  readonly text = {
    placeholder: this.I18n.t('js.relations_autocomplete.placeholder')
  };

  @Input() workPackage:WorkPackageResource;
  @Input() selectedRelationType:string;
  @Input() filterCandidatesFor:string;
  @Input() initialSelection?:WorkPackageResource;
  @Input() inputPlaceholder:string = this.text.placeholder;
  @Input() appendToContainer:string = '#content';

  @Output('onWorkPackageIdSelected') public onSelect = new EventEmitter<string|null>();
  @Output('onEscape') public onEscapePressed = new EventEmitter<KeyboardEvent>();
  @Output('onBlur') public onBlur = new EventEmitter<FocusEvent>();

  public options:any = [];
  public relatedWps:any = [];
  public noResults = false;

  private $element:JQuery;
  private $input:JQuery;

  constructor(readonly elementRef:ElementRef,
              readonly PathHelper:PathHelperService,
              readonly loadingIndicatorService:LoadingIndicatorService,
              readonly I18n:I18nService) {

  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
    const input = this.$input = this.$element.find('.wp-relations--autocomplete');
    let selected = false;

    if (this.initialSelection) {
      input.val(this.getIdentifier(this.initialSelection));
    }

    input.autocomplete({
      delay: 250,
      autoFocus: false, // Accessibility!
      appendTo: this.appendToContainer,
      classes: {
        'ui-autocomplete': 'wp-relations-autocomplete--results'
      },
      source: (request:{ term:string }, response:Function) => {
        this.autocompleteWorkPackages(request.term).then((values) => {
          selected = false;

          if (this.initialSelection) {
            values.unshift(this.initialSelection);
          }

          response(values.map(wp => {
            return {workPackage: wp, value: this.getIdentifier(wp)};
          }));
        });
      },
      select: (evt, ui:any) => {
        selected = true;
        this.onSelect.emit(ui.item.workPackage.id);
      },
      minLength: 0
    })
    .focus(() => !selected && input.autocomplete('search', input.val() as string));

    setTimeout(() => input.focus(), 20);
  }

  ngOnDestroy():void {
    this.$input.autocomplete('destroy');
  }

  public handleEnterPressed($event:KeyboardEvent) {
    let val = ($event.target as HTMLInputElement).value;
    if (!val) {
        this.onSelect.emit(null);
    }

    // If trying to enter work package ID
    if (val.match(/^#?\d+$/)) {
      val = val.replace(/^#/, '');
      this.onSelect.emit(val);
    }
  }

  private getIdentifier(workPackage:WorkPackageResource):string {
    if (workPackage) {
      return `#${workPackage.id} - ${workPackage.subject}`;
    } else {
      return '';
    }
  }

  private autocompleteWorkPackages(query:string):Promise<WorkPackageResource[]> {
    // Remove prefix # from search
    query = query.replace(/^#/, '');

    this.$element.find('.ui-autocomplete--loading').show();

    return this.workPackage.availableRelationCandidates.$link.$fetch({
      query: query,
      type: this.filterCandidatesFor || this.selectedRelationType
    }).then((collection:CollectionResource) => {
      this.noResults = collection.count === 0;
      this.$element.find('.ui-autocomplete--loading').hide();
      return collection.elements || [];
    }).catch(() => {
      this.$element.find('.ui-autocomplete--loading').hide();
      return [];
    });
  }
}
