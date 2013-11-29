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