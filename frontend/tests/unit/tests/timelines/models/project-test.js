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

/*jshint expr: true*/

describe('Project', function(){

  var Project, PlanningElement, Timeline;

  before(function(){
    this.project = Factory.build("Project", {
      timeline: Factory.build("Timeline")
    });

    this.projectEmpty = Factory.build("Project", {
      timeline: Factory.build("Timeline", {}, {
        exclude_empty: "yes"
      })
    });

  });

  beforeEach(angular.mock.module('openproject.timelines.models', 'openproject.uiComponents'));
  beforeEach(inject(function(_Project_, _PlanningElement_, _Timeline_) {
    Project         = _Project_;
    PlanningElement = _PlanningElement_;
    Timeline        = _Timeline_;
  }));

  describe('hidden', function () {
    it('should be true for empty', function () {
      expect(this.projectEmpty.hiddenForEmpty()).to.be.true;
      expect(this.projectEmpty.hide()).to.be.true;
      expect(this.project.hide()).to.be.false;
      expect(this.project.hiddenForEmpty()).to.be.false;
    });
  });

  describe('filtered', function () {
    it('should be false by default', function () {
      expect(this.project.filteredOut()).to.be.false;
    });
    it('should be filtered for type');
    it('should be filtered for status');
  });

  describe('getPlanningElements', function () {
    it('should be empty by default', function () {
      expect(this.project.getPlanningElements()).to.be.empty;
    });
    it('should return list of planningElements when set', function () {
      var pe1 = {"id": 961, "name": "B", "start_date": "2012-11-15", "due_date": "2012-11-15" };
      var pe2 = {"id": 962, "name": "B", "start_date": "2012-11-15", "due_date": "2012-11-15" };
      var pe3 = {"id": 963, "name": "D", "start_date": "2012-11-15", "due_date": "2012-11-15" };

      var testProject = Factory.build("Project", {timeline: Factory.build("Timeline"),
        planning_elements: [pe2, pe3, pe1]
      });

      var pes = testProject.getPlanningElements();

      expect(pes).to.satisfy(objectContainsAll(pe1, pe2, pe3));
    });
    it('should sort without date to the beginning', function () {
      var pe1 = {"id": 951, "name": "B",  };
      var pe2 = {"id": 952, "name": "A", "start_date": "2012-11-14", "due_date": "2012-11-18" };
      var pe3 = {"id": 953, "name": "C", "start_date": "2012-11-13", "due_date": "2012-11-17" };

      var testProject = Factory.build("Project", {timeline: Factory.build("Timeline"),
        planning_elements: [pe2, pe3, pe1]
      });

      var pes = testProject.getPlanningElements();

      expect(pes).to.satisfy(objectsortation(pe1, pe3, pe2));
    });
    it('should sort with only an end date as if it had a start date equal to the end date', function () {
      var pe1 = {"id": 951, "name": "B", "due_date": "2012-11-15"};
      var pe2 = {"id": 952, "name": "A", "start_date": "2012-11-14", "due_date": "2012-11-18" };
      var pe3 = {"id": 953, "name": "C", "start_date": "2012-11-13", "due_date": "2012-11-17" };

      var testProject = Factory.build("Project", {timeline: Factory.build("Timeline"),
        planning_elements: [pe2, pe3, pe1]
      });

      var pes = testProject.getPlanningElements();

      expect(pes).to.satisfy(objectsortation(pe3, pe2, pe1));
    });
    it('should sort by date per default', function () {
      var pe1 = {"id": 961, "name": "B", "start_date": "2012-11-15", "due_date": "2012-11-15" };
      var pe2 = {"id": 962, "name": "A", "start_date": "2012-11-14", "due_date": "2012-11-18" };
      var pe3 = {"id": 963, "name": "C", "start_date": "2012-11-13", "due_date": "2012-11-17" };

      var testProject = Factory.build("Project", {timeline: Factory.build("Timeline"),
        planning_elements: [pe2, pe3, pe1]
      });

      var pes = testProject.getPlanningElements();

      expect(pes).to.satisfy(objectsortation(pe3, pe2, pe1));
    });
    it('should sort pes with same start by end', function () {
      var pe1 = {"id": 971, "name": "B", "start_date": "2012-11-13", "due_date": "2012-11-15" };
      var pe2 = {"id": 972, "name": "A", "start_date": "2012-11-13", "due_date": "2012-11-18" };
      var pe3 = {"id": 973, "name": "C", "start_date": "2012-11-13", "due_date": "2012-11-17" };

      var testProject = Factory.build("Project", {timeline: Factory.build("Timeline"),
        planning_elements: [pe3, pe2, pe1]
      });

      var pes = testProject.getPlanningElements();

      expect(pes).to.satisfy(objectsortation(pe1, pe3, pe2));
    });
    it('should sort pes with same start and end by name', function () {
      var pe1 ={"id": 981, "name": "A", "start_date": "2012-11-13", "due_date": "2012-11-15" };
      var pe2 ={"id": 982, "name": "B", "start_date": "2012-11-13", "due_date": "2012-11-15" };
      var pe3 ={"id": 983, "name": "C", "start_date": "2012-11-13", "due_date": "2012-11-15" };

      var testProject = Factory.build("Project", {timeline: Factory.build("Timeline"),
        planning_elements: [pe3, pe2, pe1]
      });

      var pes = testProject.getPlanningElements();

      expect(pes).to.satisfy(objectsortation(pe1, pe2, pe3));
    });
    it('should sort pes with same start and end and name by id', function () {
      var pe1 = {"id": 991, "name": "A", "start_date": "2012-11-13", "due_date": "2012-11-15" };
      var pe2 = {"id": 992, "name": "A", "start_date": "2012-11-13", "due_date": "2012-11-15" };
      var pe3 = {"id": 993, "name": "A", "start_date": "2012-11-13", "due_date": "2012-11-15" };

      var testProject = Factory.build("Project", {timeline: Factory.build("Timeline"),
        planning_elements: [pe3, pe2, pe1]
      });

      var pes = testProject.getPlanningElements();

      expect(pes).to.satisfy(objectsortation(pe1, pe2, pe3));
    });
  });

  describe('responsible', function () {
    before(function () {
      this.responsible = Factory.build("User", {
        name: "testName"
      });

      this.projectWResponsible = Factory.build("Project", {
        responsible: this.responsible
      });
    });

    it('should be null by default', function () {
      expect(this.project.getResponsible()).to.be.null;
    });

    it('should get the responsible', function () {
      expect(this.projectWResponsible.getResponsible()).to.deep.equal(this.responsible);
    });
    it('should allow get of responsible name', function () {
      expect(this.projectWResponsible.getResponsibleName()).to.equal("testName");
    });
    it('should return undefined if responsible or responsible name are not set', function () {
      var projectWBrokenResponsible = Factory.build("Project", {
        responsible: {}
      });

      expect(this.project.getResponsibleName()).to.be.undefined;
      expect(projectWBrokenResponsible.getResponsibleName()).to.be.undefined;
    });
  });

  describe('assignee', function () {
    it('should always return undefined', function () {
      //we also expect it to have no side effects at all!
      var allProjects = Factory.all("Project");
      var i;
      for (i = 0; i < allProjects; i += 1) {
        expect(allProjects.getAssignee()).to.be.undefined;
      }
    });
  });

  describe('status', function () {
    it('should return null if no reporting', function () {
      expect(this.project.getProjectStatus()).to.be.null;
    });
    it('should return reporting status');
  });

  describe('subElements', function () {
    before(function () {
      this.project = Factory.build("Project", { timeline: Factory.build("Timeline") }, {
      });
    });
    it('returns pes before reporters');
    it('returns the same pes as getPlanningElements');
    it('filters the reporters correctly');
  });

  describe('Reporters', function () {
    before(function () {
      this.peWithoutDate = Factory.build("PlanningElement");
      this.peWithDate1 = Factory.build("PlanningElement", {
        "start_date": "2012-11-15",
        "due_date": "2012-11-15"
      });

      this.peWithDate2 = Factory.build("PlanningElement", {
        "start_date": "2012-11-18",
        "due_date": "2012-11-18"
      });

      this.peWithDate3 = Factory.build("PlanningElement", {
        "due_date": "2012-11-19"
      });
    });
    it('should return reporters', function () {
      var projects = Factory.buildList("Project", 10);

      var project = Factory.build("Project", {
        timeline: Factory.build("Timeline"),
        reporters: projects
      });

      expect(project.getReporters()).to.satisfy(objectContainsAll(projects));
    });
    it('should sort without date to the beginning', function () {
      var project1 = Factory.build("Project", {
        planning_elements: [this.peWithoutDate]
      });
      var project2 = Factory.build("Project", {
        planning_elements: [this.peWithDate1]
      });

      var reporterProject = Factory.build("Project", {
        timeline: Factory.build("Timeline"),
        reporters: [project2, project1]
      });

      expect(reporterProject.getReporters()).to.satisfy(objectsortation(project1, project2));
    });
    it('should sort by date', function () {
      var project1 = Factory.build("Project", {
        planning_elements: [this.peWithDate1, this.peWithoutDate]
      });
      var project2 = Factory.build("Project", {
        planning_elements: [this.peWithDate2, this.peWithoutDate]
      });
      var project3 = Factory.build("Project", {
        planning_elements: [this.peWithDate3, this.peWithoutDate]
      });

      var reporterProject = Factory.build("Project", {
        timeline: Factory.build("Timeline"),
        reporters: [project2, project3, project1]
      });

      expect(reporterProject.getReporters()).to.satisfy(objectsortation(project1, project2, project3));
    });
    it('should sort with same start and end by name', function () {
      var project1 = Factory.build("Project", {
        name: "A",
        planning_elements: [this.peWithDate1, this.peWithoutDate]
      });
      var project2 = Factory.build("Project", {
        name: "B",
        planning_elements: [this.peWithDate1, this.peWithoutDate]
      });
      var project3 = Factory.build("Project", {
        name: "C",
        planning_elements: [this.peWithDate1, this.peWithoutDate]
      });

      var reporterProject = Factory.build("Project", {
        timeline: Factory.build("Timeline"),
        reporters: [project2, project3, project1]
      });

      expect(reporterProject.getReporters()).to.satisfy(objectsortation(project1, project2, project3));
    });
    it('should sort with same start and end and name by id', function () {
      var project1 = Factory.build("Project", {
        name: "A",
        planning_elements: [this.peWithDate1, this.peWithoutDate]
      });
      var project2 = Factory.build("Project", {
        name: "A",
        planning_elements: [this.peWithDate1, this.peWithoutDate]
      });
      var project3 = Factory.build("Project", {
        name: "A",
        planning_elements: [this.peWithDate1, this.peWithoutDate]
      });

      var reporterProject = Factory.build("Project", {
        timeline: Factory.build("Timeline"),
        reporters: [project2, project3, project1]
      });

      expect(reporterProject.getReporters()).to.satisfy(objectsortation(project1, project2, project3));
    });


    describe('groups', function () {
      beforeEach(function () {
        this.project1_1 = Factory.build("Project", a().sname("F"));
        this.project1_2 = Factory.build("Project", a().sname("G"));

        this.project2_1 = Factory.build("Project", a().sname("C"));
        this.project2_2 = Factory.build("Project", a().sname("D"));

        this.project1 = Factory.build("Project", {
          name: "A",
          children: [this.project1_1, this.project1_2]
        });

        this.project2 = Factory.build("Project", {
          name: "B",
          children: [this.project2_1, this.project2_2]
        });

        this.timeline = Factory.build("Timeline", {}, {
            grouping_one_selection: [this.project2.id, this.project1.id],
            grouping_one_enabled: "yes"
        });

        this.reporterProject = Factory.build("Project", {
          timeline: this.timeline,
          reporters: [this.project1_1, this.project1_2, this.project1, this.project2_1, this.project2_2, this.project2]
        });
      });
      it('should sort groups by name', function () {
        expect(this.reporterProject.getReporters()).to.satisfy(objectsortation(this.project1_1, this.project1_2, this.project2_1, this.project2_2, this.project1, this.project2));
      });
      it('should sort groups by explicit order if given', function () {
        this.timeline.options.grouping_one_sort = 1;
        expect(this.reporterProject.getReporters()).to.satisfy(objectsortation(this.project2_1, this.project2_2, this.project1_1, this.project1_2, this.project1, this.project2));
      });
    });
  });

  describe('Parent', function () {
    it('should return null if no parent given');
    it('should return the correct parent');
  });

  describe('Url', function () {
    it('should return the correct url');
  });
});

describe('Helper Functions', function () {
  var Timeline;

  beforeEach(angular.mock.module('openproject.timelines.models'));
  beforeEach(inject(function(_Timeline_) {
    Timeline = _Timeline_;
  }));

  describe('id in Array', function () {
    it('should return true if element in array', function () {
      expect(Timeline.idInArray(["5", "4"], {id: 4})).to.be.true;
      expect(Timeline.idInArray(["5", "4"], {id: "5"})).to.be.true;
      expect(Timeline.idInArray(["a"], {id: "a"})).to.be.true;
    });

    it('should return true if no array or empty array is passed', function () {
      expect(Timeline.idInArray([], {id: 5})).to.be.true;
      expect(Timeline.idInArray("", {id: 5})).to.be.true;
    });
  });
});
