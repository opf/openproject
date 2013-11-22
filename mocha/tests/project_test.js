/*jshint expr: true*/ 

describe('Planning Element', function(){
  before(function(){

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