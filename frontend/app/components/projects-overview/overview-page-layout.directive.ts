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

import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';

export class ProjectsOverviewController {

  public selectedBlock:string|null;

  constructor(public $element:ng.IAugmentedJQuery,
              public $scope:ng.IScope,
              public $http:ng.IHttpService,
              public $compile:ng.ICompileService,
              public wpNotificationsService:WorkPackageNotificationService) {
  }

  public initialize() {
    this.updateAvailableBlocks();
  }

  public get addForm() {
    return this.$element.find('#add-block-form');
  }

  public get saveForm() {
    return this.$element.find('#save-block-form');
  }

  public get hiddenContainer() {
    return this.$element.find('#list-hidden');
  }

  /**
   * Retrieve block identifiers in the given container
   */
  public activeBlockNames(container?:JQuery) {
    if (!container) {
      container = this.$element;
    }

    return container.find('.widget-box').map((i:number, el:HTMLElement) => {
      return this.blockNameFromId(el.id);
    }).toArray();
  }

  /**
   * Remember removed custom blocks, since they need to be removed in backend.
   */
  public noteRemovedBlock(blockName:string) {
    angular.element('<input>')
      .attr({ type: 'hidden', name: 'deleted_custom_blocks[]', value: blockName })
      .appendTo(this.saveForm);
  }

  /**
   * Disables or activates block options in the block selection.
   * Should be replaced with ng-model but this was more or less moved from prototype
   */
  public updateAvailableBlocks() {
    var currentBlocks = this.activeBlockNames();

    this.$element.find('#block-select option').each((i, el) => {
      var option = angular.element(el);
      var blockName = option.val();
      var isDisabled = blockName === '' || currentBlocks.indexOf(blockName) !== -1;

      option.prop('disabled', isDisabled);
    });
  }

  /**
   * Given the block identifier (e.g., block_work_packages_watched), return the block name.
   */
  public blockNameFromId(id:string):string {
    return id.replace(/^block_/, '');
  }

  /**
   * Given the block name (e.g., work_packages_watched), return the selector to the dom block.
   */
  public idFromBlockName(name:string):string {
    return "#block_" + name;
  }

  public handleSaveChanges() {
    this.$element.find('.widget-container').each((i, el) => {
      var container = angular.element(el);
      var group = container.data('position');
      var ids = this.activeBlockNames(container);

      this.saveForm.find('[name=' + group + ']').val(ids.join(','));
    });
  }

  public handleBlockSelection() {
    this.$http({
      url: this.addForm.attr('action'),
      method: 'POST',
      data: { block: this.selectedBlock },
      headers: { Accept: 'text/html' }
    }).then((response:{data: any}) => {
      var blockName = response.data.match(/id="block_(.*?)"/)[1];
      this.addBlock(blockName, response.data);
      this.updateAvailableBlocks();
    }).catch(error => {
      this.wpNotificationsService.handleErrorResponse(error);
    }).finally(() => {
      this.selectedBlock = null;
    });
  }

  /**
   * Refresh an existing (custom) block from the backend
   */
  public updateBlock(blockName:string, content:string) {
    var block = this.$element.find(this.idFromBlockName(blockName));
    content = this.compileBlock(content);

    block.replaceWith(content);
  }

  /**
   * Refresh the attachments on the page layout
   */
   public updateAttachments() {
     var attachments = this.$element.find('#page_layout_attachments');
     this.$http({
       url: attachments.data('refreshUrl'),
       method: 'GET',
       headers: { Accept: 'text/html' }
    }).then((response:any) => {
      attachments.html(response.data);
    }).catch(error => {
      this.wpNotificationsService.handleErrorResponse(error);
    });
   }

  private addBlock(blockName:string, content:string) {
    content = this.compileBlock(content);

    // Add the block to hidden by default
    this.hiddenContainer.append(content);
    this.$element.find(this.idFromBlockName(blockName))[0].scrollIntoView();
  }

  private compileBlock(content:string) {
    let compileFn:any = this.$compile(content);
    return compileFn(this.$scope, undefined, {
      transcludeControllers: {
        overviewPageLayout: { instance: this }
      }
    });
  }
}

function overviewPageLayout():any {
  return {
    restrict: 'E',
    scope: {},
    transclude: true,
    compile: function() {
      return function(
        scope:any,
        element:ng.IAugmentedJQuery,
        attrs:ng.IAttributes,
        ctrls:any,
        transclude:any) {
        transclude(scope, (clone:any) => {
          element.append(clone);
          scope.$ctrl.initialize();
        });
      };
    },
    bindToController: true,
    controller: ProjectsOverviewController,
    controllerAs: '$ctrl'
  };
}

angular.module('openproject').directive('overviewPageLayout', overviewPageLayout);
