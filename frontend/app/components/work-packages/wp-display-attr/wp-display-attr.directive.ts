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

import {HalResource} from "../../api/api-v3/hal-resources/hal-resource.service";
import {wpDirectivesModule} from "../../../angular-modules";
import {WorkPackageEditFieldController} from "../../wp-edit/wp-edit-field/wp-edit-field.directive";
import {WorkPackageCacheService} from "../work-package-cache.service";
import {DisplayField} from "../../wp-display/wp-display-field/wp-display-field.module";
import {WorkPackageDisplayFieldService} from "../../wp-display/wp-display-field/wp-display-field.service";

export class WorkPackageDisplayAttributeController {

  public wpEditField: WorkPackageEditFieldController;
  public attribute: string;
  public placeholderOptional: string;
  public workPackage: any;
  public customSchema: HalResource;
  public field: DisplayField;
  public labelOptional: string;

  private __d__hiddenForSighted: JQuery;
  private __d__cell: JQuery;
  private __d__renderer: JQuery;

  constructor(protected $element: JQuery,
              protected wpDisplayField: WorkPackageDisplayFieldService,
              protected wpCacheService: WorkPackageCacheService,
              protected $scope: ng.IScope) {

    // Update the attribute initially
    if (this.workPackage) {
      this.updateAttribute(this.workPackage);
    }
  }

  public activateIfEditable(event) {
    if (this.wpEditField.isEditable) {
      this.wpEditField.handleUserActivate();
    }
    event.stopImmediatePropagation();
  }

  public get placeholder() {
    return this.placeholderOptional || (this.field && this.field.placeholder);
  };

  public get label() {
    return this.labelOptional ||
      (this.schema[this.attribute] && this.schema[this.attribute].name) ||
      this.attribute;
  };

  public isEditable() {
    return this.wpEditField && this.wpEditField.isEditable;
  };

  public shouldFocus() {
    return this.wpEditField && this.wpEditField.shouldFocus();
  }

  public get labelId(): string {
    return 'wp-' + this.workPackage.id + '-display-attr-' + this.attribute + '-aria-label';
  }

  public get isEmpty(): boolean {
    return !this.field || this.field.isEmpty();
  }

  /**
   * The display attribute is either used for a work package, or a custom resource and schema
   * (sumsSchema)
   */
  public get schema(): HalResource {
    return this.customSchema || this.workPackage.schema;
  }

  public get displayText(): string {
    if (this.isEmpty) {
      return this.placeholder;
    }
    else {
      return this.field.valueString;
    }
  }

  protected updateAttribute(wp) {
    this.workPackage = wp;
    this.schema.$load().then(() => {
      this.field = <DisplayField>this.wpDisplayField.getField(this.workPackage, this.attribute, this.schema[this.attribute]);

        if (this.field.isManualRenderer) {
          this.__d__renderer = this.__d__renderer || this.$element.find(".__d__renderer");
          this.field.render(this.__d__renderer, this);
        }

        this.__d__hiddenForSighted = this.__d__hiddenForSighted || this.$element.find(".__d__hidden-for-sighted");
        this.__d__hiddenForSighted.attr("id", this.labelId);
        this.__d__hiddenForSighted.text(this.label + " " + this.displayText);

        this.__d__cell = this.__d__cell || this.$element.find(".__d__cell");
        this.__d__cell.attr("tabindex", this.isEditable() ? "0" : "-1");
        this.__d__cell.attr("aria-labelledby", this.labelId);
        this.__d__cell.toggleClass("-placeholder", this.isEmpty);
    });
  }
}

function wpDisplayAttrDirective() {

  function wpTdLink(scope,
                    element,
                    attr,
                    controllers) {

    scope.$ctrl.wpEditField = controllers[0];

    // Listen for changes to the work package on the form ctrl
    var formCtrl = controllers[1];

    if (formCtrl && !scope.$ctrl.customSchema) {
      formCtrl.onWorkPackageUpdated('wp-display-attr-' + scope.$ctrl.attribute, (wp) => {
        scope.$ctrl.updateAttribute(wp);
      });
    }
  }

  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/components/work-packages/wp-display-attr/wp-display-attr.directive.html',
    require: ['^?wpEditField', '^?wpEditForm'],
    link: wpTdLink,

    scope: {
      workPackage: '=',
      customSchema: '=?',
      attribute: '=',
      labelOptional: '=label',
      placeholderOptional: '=placeholder'
    },

    bindToController: true,
    controller: WorkPackageDisplayAttributeController,
    controllerAs: '$ctrl'
  };
}

wpDirectivesModule.directive('wpDisplayAttr', wpDisplayAttrDirective);
