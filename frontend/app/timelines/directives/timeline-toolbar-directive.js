//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

module.exports = function(I18n) {

  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/timelines/toolbar.html',
    scope: { timeline: '=' },
    controller: function() {
      var vm = this;

      vm.currentScale = 'monthly';

      vm.updateToolbar = function() {
        vm.currentOutlineLevel = vm.timeline.OUTLINE_LEVELS[vm.timeline.expansionIndex];
        vm.currentScale = vm.timeline.ZOOM_SCALES[vm.timeline.zoomIndex];
      };

      vm.increaseZoom = function() {
        var scaleIndex = vm.timeline.ZOOM_SCALES.indexOf(vm.currentScale);

        if(scaleIndex < Object.keys(vm.timeline.ZOOM_CONFIGURATIONS).length - 1) {
          scaleIndex++;
        }
        vm.currentScale = vm.timeline.ZOOM_SCALES[scaleIndex];
      };

      vm.decreaseZoom = function() {
        var scaleIndex = vm.timeline.ZOOM_SCALES.indexOf(vm.currentScale);

        if(scaleIndex > 0) {
          scaleIndex--;
        }
        vm.currentScale = vm.timeline.ZOOM_SCALES[scaleIndex];
      };

      vm.resetOutline = function(){
        vm.timeline.expandTo(0);
        vm.currentOutlineLevel = vm.timeline.OUTLINE_LEVELS[vm.timeline.expansionIndex];
      };
    },
    controllerAs: 'ctrl',
    bindToController: true,
    link: function(scope, _element, _attributes, ctrl) {
      scope.I18n = I18n;

      scope.$watch('ctrl.currentScale', function(newScale, oldScale){
        if (newScale !== oldScale) {
          var scaleIndex = ctrl.timeline.ZOOM_SCALES.indexOf(ctrl.currentScale);

          ctrl.timeline.zoom(scaleIndex);
        }
      });

      scope.$watch('ctrl.currentOutlineLevel', function(outlineLevel, formerLevel) {
        if (outlineLevel !== formerLevel) {
          ctrl.timeline.expansionIndex = ctrl.timeline.OUTLINE_LEVELS.indexOf(outlineLevel);
          ctrl.timeline.expandToOutlineLevel(outlineLevel); // TODO replace event-driven adaption by bindings
        }
      });

      ctrl.updateToolbar();
    }
  };
};
