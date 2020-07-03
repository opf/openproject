//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++
(function($) {
  $(function() {
    /*
     * See /app/views/timelog/_date_range.html.erb
     */
    if ($('#date-range').length < 1) {
      return;
    }
    var intervalInputs = $('#to, #from'),
        // select
        period = $('#period'),
        // radio buttons
        periodOptionList = $('#period_type_list'),
        periodOptionInterval = $('#period_type_interval');

    var disableInputFields = function(radioButton) {
      return function () {
        if (radioButton == periodOptionList) {
          jQuery('#period').attr("tabindex", -1);
          jQuery('#from').removeAttr("tabindex");
          jQuery('#to').removeAttr("tabindex");
        }
        else {
          jQuery('#from').attr("tabindex", -1);
          jQuery('#to').attr("tabindex", -1);
          jQuery('#period').removeAttr("tabindex");
        }
      };
    };

    jQuery(document).ready(function() {
      if (periodOptionInterval.is(':checked')) {
        jQuery('#period').attr("tabindex", -1);
      }
      else {
        jQuery('#from').attr("tabindex", -1);
        jQuery('#to').attr("tabindex", -1);
      }
    });

    periodOptionList.on('change', disableInputFields(periodOptionInterval));
    periodOptionInterval.on('change', disableInputFields(periodOptionList));

  });
}(jQuery));
