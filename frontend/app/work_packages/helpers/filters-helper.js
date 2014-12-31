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
  var FiltersHelper = {

    assignAncestorLevels: function(projects){
      var ancestors = [];
      angular.forEach(projects, function(project, i){
        while(ancestors.length > 0 && project.parent_id !== _.last(ancestors).id) {
          // this helper method only reflects hierarchies if nested projects follow one another
          ancestors.pop();
        }

        project['level'] = ancestors.length;
        project['name'] = FiltersHelper.indentedName(project['name'], project['level']);

        if (!project['leaf?']) {
          ancestors.push(project);
        }
      });
      return projects;
    },

    indentedName: function(name, level){
      var indentation = '';
      for(var i = 0; i < level; i++){
        indentation = indentation + '--';
      }
      return indentation + " " + name;
    },

    localisedFilterName: function(filter){
      if(filter){
        if(filter.name){
          return filter.name;
        }
        if(filter.locale_name){
          return I18n.t('js.filter_labels.' + filter["locale_name"]);
        }
      }
      return "";
    },
  };

  return FiltersHelper;
};
