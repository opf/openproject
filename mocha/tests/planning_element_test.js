describe('Timeline', function () {
  it('should create a timeline object', function () {
    Timeline.startup({
      project_id: 1
    });
  });
});

describe('Planning Element', function(){
  before(function(){
    this.pe = planningElementFactory.create({
      "start_date": "2012-11-11",
      "due_date": "2012-11-10"
    });
    this.pe2 = planningElementFactory.create();
  });

  describe('start() and end()', function(){
    it('should return date object', function(){
      expect(this.pe.start()).to.be.an.instanceof(Date);
      expect(this.pe.end()).to.be.an.instanceof(Date);
    });

    it('should return correct date', function () {
      expect(this.pe.start().getTime()).to.equal(1352588400*1000);
      expect(this.pe.end().getTime()).to.equal(1352502000*1000);
    });

    it('should have no historical', function () {
      expect(this.pe.has_historical()).to.be.false;
    });

    it('should return undefined for no date' , function () {
      expect(this.pe2.start()).to.not.exist;
      expect(this.pe2.end()).to.not.exist;
    });
  });
});