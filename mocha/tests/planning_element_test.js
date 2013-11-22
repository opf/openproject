/*jshint expr: true*/ 

describe('Timeline', function () {
  it('should create a timeline object', function () {
    Timeline.startup({
      project_id: 1
    });
  });
});

describe('Planning Element', function(){
  before(function(){
    this.peEmpty = planningElementFactory.create();

    this.peWithDates = planningElementFactory.create({
      "start_date": "2012-11-11",
      "due_date": "2012-11-10"
    });

    this.peWithHistorical = planningElementFactory.create({
      historical_element: this.peWithDates
    });

    this.peWithNameA = planningElementFactory.create({
      name: "A"
    });

    this.peWithNameB = planningElementFactory.create({
      name: "B"
    });

    this.peWithChildren = planningElementFactory.create({
      planning_elements: [this.peWithDates, this.peEmpty, this.peWithNameA, this.peWithNameB]
    });
  });

  describe('is', function () {
    it('should return true for pes', function () {
      expect(Timeline.PlanningElement.is(this.peWithDates)).to.be.true;
    });

    it('should return false for non-pes', function () {
      expect(Timeline.PlanningElement.is({})).to.be.false;
    });
  });

  describe('children', function () {
    it('should return sorted children', function () {
      var children = this.peWithChildren.getChildren();
      expect(children).to.deep.equal([this.peEmpty, this.peWithNameA, this.peWithNameB, this.peWithDates]);
    });

    it('should return empty list', function () {
      expect(this.peWithDates.getChildren()).to.be.empty;
    });
  });

  describe('historical', function () {
    it('empty should have no historical', function () {
      expect(this.peEmpty.has_historical()).to.be.false;
      expect(this.peEmpty.historical()).to.deep.equal({});
    });

    it('empty should have no alternate dates', function () {
      expect(this.peWithDates.hasAlternateDates()).to.be.falsy;
    });

    it('historical should have correct alternate dates', function () {
      expect(this.peWithHistorical.hasAlternateDates()).to.be.true;
      expect(this.peWithHistorical.alternate_start().getTime()).to.equal(1352588400*1000);
      expect(this.peWithHistorical.alternate_end().getTime()).to.equal(1352502000*1000);
    });
  });

  describe('start() and end()', function(){
    it('should return date object', function(){
      expect(this.peWithDates.start()).to.be.an.instanceof(Date);
      expect(this.peWithDates.end()).to.be.an.instanceof(Date);
      expect(this.peWithDates.hasStartDate()).to.be.true;
      expect(this.peWithDates.hasEndDate()).to.be.true;
      expect(this.peWithDates.hasBothDates()).to.be.true;
      expect(this.peWithDates.hasOneDate()).to.be.true;
    });

    it('should return correct date', function () {
      expect(this.peWithDates.start().getTime()).to.equal(1352588400*1000);
      expect(this.peWithDates.end().getTime()).to.equal(1352502000*1000);
    });

    it('should return undefined for no date' , function () {
      expect(this.peEmpty.start()).to.not.exist;
      expect(this.peEmpty.end()).to.not.exist;

      expect(this.peEmpty.hasStartDate()).to.be.false;
      expect(this.peEmpty.hasEndDate()).to.be.false;
      expect(this.peEmpty.hasBothDates()).to.be.false;
      expect(this.peEmpty.hasOneDate()).to.be.false;
    });
  });
});