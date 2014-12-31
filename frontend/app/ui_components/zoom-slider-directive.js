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

module.exports = function(I18n) {

  function makeSliderAccessible(slider) {
    var defaultLabel = angular.element('<span class="hidden-for-sighted">');
    var sliderLabel = defaultLabel.text(I18n.t('js.timelines.zoom.slider'));
    var sliderHandle = slider.find('a.ui-slider-handle');

    sliderHandle.append(sliderLabel);
  }

  // TODO pass options to directive and do not refer to timelines
  return {
    restrict: 'A',
    link: function(scope, element, attributes) {
      scope.currentScaleIndex = Timeline.ZOOM_SCALES.indexOf(scope.currentScaleName);
      scope.slider = element.slider({
        min: 1,
        max: Timeline.ZOOM_SCALES.length,
        range: 'min',
        value: scope.currentScaleIndex + 1,
        slide: function(event, ui) {
          scope.currentScaleIndex = ui.value - 1;
          scope.$apply();
        },
        change: function(event, ui) {
          scope.currentScaleIndex = ui.value - 1;
        }
      }).css({
        // top right bottom left
        'margin': '4px 6px 3px'
      });

      // Slider
      // TODO integrate angular-ui-slider

      makeSliderAccessible(scope.slider);

      scope.$watch('currentScaleIndex', function(newIndex){
        scope.currentScaleIndex = newIndex;

        var newScaleName = Timeline.ZOOM_SCALES[newIndex];
        if (scope.currentScaleName !== newScaleName) {
          scope.currentScaleName = newScaleName;
        }
      });

    }
  };
};
