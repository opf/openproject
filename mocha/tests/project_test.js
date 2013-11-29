/*jshint expr: true*/ 

describe('Project', function(){
  before(function(){
    this.project = Factory.build("Project", {
      timeline: {
        options: Factory.build("options")
      }
    });

    this.projectEmpty = Factory.build("Project", {
      timeline: {
        options: {
          exclude_empty: "yes"
        }
      }
    });

  });

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
    it('should return list of planningElements when set');
    it('should sort by date per default');
    it('should sort pes with same start by end');
    it('should sort pes with same start and end by name');
    it('should sort pes with same start and end and name by id');
  });

  describe('responsible', function () {
    before(function () {
      this.responsible = {
        name: "testName"
      };

      this.projectWResponsible = Factory.build("Project", {
        responsible: this.responsible
      });

      this.projectWBrokenResponsible = Factory.build("Project", {
        responsible: {}
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
      expect(this.project.getResponsibleName()).to.be.undefined;
      expect(this.projectWBrokenResponsible.getResponsibleName()).to.be.undefined;
    });
  });

  describe('assignee', function () {
    it('should always return undefined');
  });

  describe('status', function () {
    it('should return null if no reporting', function () {
      expect(this.project.getProjectStatus()).to.be.null;
    });
    it('should return reporting status');
  });

  describe('subElements', function () {
    it('returns pes before reporters');
    it('returns the same pes as getPlanningElements');
    it('filters the reporters correctly');
  });

  describe('PlanningElements', function () {
    it('should return pes of project');
    it('should sort without date to the beginning');
    it('should sort by date');
    it('should sort with only an end date as if it had a start date equal to the end date');
    it('should sort with same start by end date');
    it('should sort with same start and end by name');
    it('should sort with same start and end and name by id');
  });

  describe('Reporters', function () {
    it('should return reporters');
    it('should sort without date to the beginning');
    it('should sort by date');
    it('should sort with same start by end date');
    it('should sort with same start and end by name');
    it('should sort with same start and end and name by id');


    describe('groups', function () {
      it('should sort project with same group next to each other');
      it('should sort groups by name');
      it('should sort groups by explicit order if given');
      it('should sort projects with other group to the end');
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