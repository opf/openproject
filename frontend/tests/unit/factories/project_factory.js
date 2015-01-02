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

(function(Project, PlanningElement, Reporting) {

  function addProjectToOwnTimeline(Project) {
    if (Project && Project.timeline) {
      var t = Project.timeline;
      t.projects = t.projects || {};

      t.projects[Project.id] = Project;
    }
  }

  Factory.define('Project', Project)
    .sequence('id')
    .sequence('name', function (i) {return "Project No. " + i;})
    .sequence('identifier', function (i) {return "projectno" + i;})
    .attr('description', 'Description for Project')
    .after(function(Project) {
      if(Project && Project.planning_elements) {
        var i;
        for (i = 0; i < Project.planning_elements.length; i += 1) {
          var current = Project.planning_elements[i];
          current.project = Project;
          current.parent = Project;
          current.timeline = Project.timeline;

          if (!PlanningElement.is(current)) {
            Project.planning_elements[i] = Factory.build('PlanningElement', current);
          }
        }
      }
    })
    .after(function(Project) {
      if(Project && Project.children) {
        var i;
        for (i = 0; i < Project.children.length; i += 1) {
          var current = Project.children[i];
          current.project = Project;
          current.parent = Project;
          current.timeline = Project.timeline;

          addProjectToOwnTimeline(current);

          if (!current.is(Project)) {
            Project.children[i] = Factory.build('Project', current);
          }
        }
      }
    })
    .after(function(Project) {
      if(Project && Project.reporters) {
        var i;
        for (i = 0; i < Project.reporters.length; i += 1) {
          var current = Project.reporters[i];
          current.timeline = Project.timeline;
          addProjectToOwnTimeline(current);

          if (current.identifier !== Reporting.identifier) {
            Project.reporters[i] = Factory.build('Reporting', current);
          }
        }
      }
    })
    .after(function (Project) {
      addProjectToOwnTimeline(Project);
    });

})($injector.get('Project'), $injector.get('PlanningElement'), $injector.get('Reporting'));
