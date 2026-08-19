//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { Component, ChangeDetectionStrategy, OnInit, ViewChild, inject } from '@angular/core';
import { EditFieldComponent } from 'core-app/shared/components/fields/edit/edit-field.component';
import { ValueOption } from 'core-app/shared/components/fields/edit/field-types/select-edit-field/select-edit-field.component';
import { NgSelectComponent } from '@ng-select/ng-select';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { repositionDropdownBugfix } from 'core-app/shared/components/autocompleter/op-autocompleter/autocompleter.helper';

@Component({
  templateUrl: './multi-select-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class MultiSelectEditFieldComponent extends EditFieldComponent implements OnInit {
  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;

  readonly pathHelperService = inject(PathHelperService);

  groupByFn = (item:HalResource):string|null => {
    if (!this.isVersionResource) return null;
    const project = item.definingProject as HalResource | undefined;
    return project?.name || this.I18n.t('js.project.not_available');
  };

  public availableOptions:any[] = [];

  public text = {
    requiredPlaceholder: this.I18n.t('js.placeholders.selection'),
    placeholder: this.I18n.t('js.placeholders.default'),
    save: this.I18n.t('js.inplace.button_save', { attribute: this.schema.name }),
    cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.schema.name }),
  };

  public appendTo:any = null;

  public currentValueInvalid = false;

  public showAddNewUserButton:boolean;

  private hiddenOverflowContainer = '.__hidden_overflow_container';

  private nullOption:ValueOption;

  private _selectedOption:ValueOption[];

  /** Since we need to wait for values to be loaded, remember if the user activated this field */
  private requestFocus = false;

  ngOnInit() {
    this.nullOption = { name: this.text.placeholder, href: null };
    this.showAddNewUserButton = this.schema.type === 'User';

    this.handler
      .$onUserActivate
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe(() => {
        this.requestFocus = this.availableOptions.length === 0;

        // If we already have all values loaded, open now.
        if (!this.requestFocus) {
          this.openAutocompleteSelectField();
        }
      });

    super.ngOnInit();
    this.appendTo = this.overflowingSelector;
  }

  public get value() {
    const val = this.resource[this.name];
    return val ? val[0] : val;
  }

  /**
   * Map the selected hal resource(s) to the value options so that ngOptions will track them.
   * We cannot pass the HalResources themselves as angular will copy them on every digest due to trackBy
   * @returns {any}
   */
  public buildSelectedOption() {
    const value:HalResource[] = this.resource[this.name];
    return value ? (Array.isArray(value) ? value : [value]).map((val) => this.findValueOption(val)) : [];
  }

  public get selectedOption() {
    return this._selectedOption;
  }

  /**
   * Map the ValueOption to the actual HalResource option
   * @param val
   */
  public set selectedOption(val:ValueOption[]) {
    this._selectedOption = val;
    const mapper = (val:ValueOption) => {
      const option = (this.availableOptions as ValueOption[]).find((o) => o.href === val.href) ?? this.nullOption;

      // Special case 'null' value, which angular
      // only understands in ng-options as an empty string.
      if (option?.href === '') {
        option.href = null;
      }

      return option;
    };

    (this.resource as Record<string, ValueOption[]>)[this.name] = (Array.isArray(val) ? val : [val]).map((el) => mapper(el) as ValueOption);
  }

  public onOpen() {
    document.querySelector(this.hiddenOverflowContainer)?.addEventListener('scroll', () => {
      this.ngSelectComponent.close();
    }, { once: true });
  }

  public onClose() {
    // Nothing to do
  }

  public repositionDropdown() {
    repositionDropdownBugfix(this.ngSelectComponent);
  }

  private openAutocompleteSelectField() {
    // The timeout takes care that the opening is added to the end of the current call stack.
    // Thus we can be sure that the autocompleter is rendered and ready to be opened.
    window.setTimeout(() => {
      this.ngSelectComponent.open();
    }, 0);
  }

  private findValueOption(option?:HalResource):ValueOption {
    let result:ValueOption|undefined;

    if (option) {
      result = (this.availableOptions as ValueOption[]).find((valueOption) => valueOption.href === option.href)!;
    }

    return result || this.nullOption;
  }

  private setValues(availableValues:any[], sortValuesByName = false) {
    if (sortValuesByName) {
      availableValues.sort((a:any, b:any) => {
        const nameA = a.name.toLowerCase();
        const nameB = b.name.toLowerCase();
        return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
      });
    }

    this.availableOptions = this.filterInvalidValues(availableValues || []);
    this._selectedOption = this.buildSelectedOption();
    this.checkCurrentValueValidity();

    if (this.availableOptions.length > 0 && this.requestFocus) {
      this.openAutocompleteSelectField();
      this.requestFocus = false;
    }
  }

  protected initialize() {
    super.initialize();
    this.loadValues();
  }

  private loadValues() {
    const { allowedValues } = this.schema;
    if (Array.isArray(allowedValues)) {
      this.setValues(allowedValues);
    } else if (this.schema.allowedValues) {
      return (this.schema.allowedValues.$load() as Promise<CollectionResource>).then((values:CollectionResource) => {
        // The select options of the project shall be sorted
        if (values.count > 0 && (values.elements[0] as any)._type === 'Project') {
          this.setValues(values.elements, true);
        } else {
          this.setValues(values.elements);
        }

        if (this.requestFocus) {
          // Focus and open the field once the values are loaded
          this.ngSelectComponent.focus();
          this.openAutocompleteSelectField();
        }
      });
    } else {
      this.setValues([]);
    }
    return Promise.resolve();
  }

  private filterInvalidValues(availableValues:HalResource[]) {
    return availableValues.filter((value) => !!value.name);
  }

  private checkCurrentValueValidity() {
    if (this.value) {
      const resourceValue = (this.resource as Record<string, HalResource[]|HalResource>)[this.name];
      const values = Array.isArray(resourceValue) ? resourceValue : [resourceValue];
      // (If value AND)
      // MultiSelect AND there is no value which href is not in the options hrefs
      this.currentValueInvalid = !values.some((value:HalResource) => (this.availableOptions as ValueOption[]).some((option) => (option.href === value.href)));
    } else {
      // If no value but required
      this.currentValueInvalid = !!this.schema.required;
    }
  }

  /**
   * For multi-select fields that are of type User, we want to show a hover card when hovering over users in the
   * dropdown. For this to happen we must register a trigger target.
   */
  protected getHoverCardTriggerTarget() {
    if (this.isUserResource) {
      return 'trigger';
    }

    return '';
  }

  /**
   * For multi-select fields that are of type User, we want to show a hover card when hovering over users in the
   * dropdown. For this to happen, we must define a URL for the hover card.
   */
  protected getHoverCardUrl(item:HalResource) {
    if (item instanceof UserResource && item.id) {
      return this.pathHelperService.userHoverCardPath(item.id);
    }

    return '';
  }

  protected readonly getComputedStyle = getComputedStyle;

  private get isUserResource() {
    const type = this.schema?.type;
    return type && type.indexOf('User') > 0;
  }

  private get isVersionResource() {
    const type = this.schema?.type;
    return type && type.indexOf('Version') > 0;
  }
}
