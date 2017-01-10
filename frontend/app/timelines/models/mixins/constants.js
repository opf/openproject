// //-- copyright
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

// // ╭───────────────────────────────────────────────────────────────╮
// // │  _____ _                _ _                                   │
// // │ |_   _(_)_ __ ___   ___| (_)_ __   ___  ___                   │
// // │   | | | | '_ ` _ \ / _ \ | | '_ \ / _ \/ __|                  │
// // │   | | | | | | | | |  __/ | | | | |  __/\__ \                  │
// // │   |_| |_|_| |_| |_|\___|_|_|_| |_|\___||___/                  │
// // ├───────────────────────────────────────────────────────────────┤
// // │ Javascript library that fetches and plots timelines for the   │
// // │ OpenProject timelines module.                                 │
// // ╰───────────────────────────────────────────────────────────────╯

module.exports = function() {

  var Constants = {
    //constants and defaults
    LOAD_ERROR_TIMEOUT: 60000,
    DISPLAY_ERROR_DELAY: 2000,
    PROJECT_ID_BLOCK_SIZE: 100,
    USER_ATTRIBUTES: {
      PROJECT: ["responsible_id"],
      PLANNING_ELEMENT: ["responsible_id", "assigned_to_id"]
    },

    defaults: {
      artificial_load_delay:          0,   // no delay
      columns:                        [],
      exclude_own_planning_elements:  false,
      exclude_reporters:              false,
      api_prefix:                     '/api/v2',
      hide_other_group:               false,
      hide_tree_root:                 false,
      initial_outline_expansion:      0,   // aggregations only
      project_prefix:                 '/projects',
      planning_element_prefix:        '',
      ui_root:                        jQuery('#timeline'),
      url_prefix:                     ''   // empty prefix so it is not undefined.
    },

    ajax_defaults: {
      cache: false,
      context: this,
      dataType: 'json'
    },
  };

  return Constants;
};
