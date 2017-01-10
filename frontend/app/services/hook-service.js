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

module.exports = function() {
  var hooks = { };

  var HookService = {
    register: function(id, callback) {
      if (callback && typeof(callback) == "function") {
        if (!hooks[id]) {
          hooks[id] = [];
        }

        hooks[id].push(callback);
      }
    },
    call: function(id, params) {
      var results = [];

      if (hooks[id]) {
        for (var x = 0; x < hooks[id].length; x++) {
          var result = hooks[id][x](params);

          if (result) {
            results.push(result);
          }
        }
      }

      return results;
    }
  };

  return HookService;
};
