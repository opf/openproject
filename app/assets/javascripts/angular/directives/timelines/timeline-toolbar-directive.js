//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

angular.module('openproject.timelines.directives')

.directive('timelineToolbar', ['TimelineTableHelper', 'Timeline', function(TimelineTableHelper, Timeline) {

  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/timelines/toolbar.html',
    link: function(scope) {
      scope.scaleOptions = Timeline.ZOOM_SCALES;
      scope.currentScaleName = 'monthly';

      scope.updateToolbar = function() {
        scope.slider.slider('value', scope.timeline.zoomIndex + 1);
        scope.currentOutlineLevel = Timeline.OUTLINE_LEVELS[scope.timeline.expansionIndex];
        scope.currentScaleName = Timeline.ZOOM_SCALES[scope.timeline.zoomIndex];
      };

      scope.increaseZoom = function() {
        if(scope.currentScaleIndex < Object.keys(Timeline.ZOOM_CONFIGURATIONS).length - 1) {
          scope.currentScaleIndex++;
        }
      };
      scope.decreaseZoom = function() {
        if(scope.currentScaleIndex > 0) {
          scope.currentScaleIndex--;
        }
      };
      scope.resetOutline = function(){
        scope.timeline.expandTo(0);
      };

      scope.$watch('currentScaleName', function(newScaleName, oldScaleName){
        if (newScaleName !== oldScaleName) {
          scope.currentScale = Timeline.ZOOM_CONFIGURATIONS[scope.currentScaleName].scale;
          scope.timeline.scale = scope.currentScale;

          scope.currentScaleIndex = Timeline.ZOOM_SCALES.indexOf(scope.currentScaleName);
          scope.slider.slider('value', scope.currentScaleIndex + 1);

          scope.timeline.zoom(scope.currentScaleIndex); // TODO replace event-driven adaption by bindings
        }
      });

      scope.$watch('currentOutlineLevel', function(outlineLevel, formerLevel) {
        if (outlineLevel !== formerLevel) {
          scope.timeline.expansionIndex = Timeline.OUTLINE_LEVELS.indexOf(outlineLevel);
          scope.timeline.expandToOutlineLevel(outlineLevel); // TODO replace event-driven adaption by bindings
          TimelineTableHelper.setRowLevelVisibility(scope.rows, scope.timeline.expansionIndex);
        }
      });
    }
  };
}]);
