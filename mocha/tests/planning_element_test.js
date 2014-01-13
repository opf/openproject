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
    this.peEmpty = Factory.build("PlanningElement", {
      timeline: Factory.build("Timeline"),
    });

    this.peWithDates = Factory.build("PlanningElement", {
      timeline: Factory.build("Timeline"),
      "start_date": "2012-11-11",
      "due_date": "2012-11-12"
    });
  });

  describe('is', function () {
    it('should return true for pes', function () {
      expect(Timeline.PlanningElement.is(this.peWithDates)).to.be.true;
      expect(this.peWithDates.is(Timeline.PlanningElement)).to.be.true;
    });

    it('should return false for non-pes', function () {
      expect(Timeline.PlanningElement.is({})).to.be.false;
    });
  });

  describe('children', function () {
    before(function () {
      this.peWithNameA = Factory.build("PlanningElement", {
        name: "A"
      });

      this.peWithNameB = Factory.build("PlanningElement", {
        name: "B"
      });

      this.peWithNameC = Factory.build("PlanningElement", {
        name: "C"
      });

      this.peWithChildren = Factory.build("PlanningElement", {
        planning_elements: [this.peWithDates, this.peWithNameC, this.peWithNameA, this.peWithNameB]
      });
    });

    describe('getChildren', function () {
      it('should return sorted children', function () {
        var children = this.peWithChildren.getChildren();
        expect(children).to.satisfy(objectsortation(this.peWithNameA, this.peWithNameB, this.peWithNameC, this.peWithDates));
      });

      it('should return empty list', function () {
        expect(this.peWithDates.getChildren()).to.be.empty;
      });

      describe('when start and due dates are specified', function() {
        before(function(){
          this.peAWithDates = Factory.build("PlanningElement", {
            "name": "A",
            "start_date": "2012-11-13"
          });

          this.peBWithDates = Factory.build("PlanningElement", {
            name: "B",
            "start_date": "2012-11-11",
            "due_date": "2012-11-15"
          });

          this.peCWithDates = Factory.build("PlanningElement", {
            name: "C",
            "start_date": "2012-11-11",
            "due_date":  "2012-11-14"
          });

          this.peDWithDates = Factory.build("PlanningElement", {
            name: "D",
            "start_date": "2012-11-13"
          });

          this.peWithChildren.planning_elements.push(this.peAWithDates, this.peBWithDates, this.peCWithDates, this.peDWithDates);

          this.children = this.peWithChildren.getChildren();
        });

        it('orders work packages by name if start and due dates are equal', function(){
          expect(this.children.indexOf(this.peDWithDates)).to.be.above(this.children.indexOf(this.peAWithDates));
        });

        it.skip('shows work packages with earlier start dates first', function(){
          expect(this.children.indexOf(this.peAWithDates)).to.be.above(this.children.indexOf(this.peBWithDates));
        });

        it.skip('shows work packages with sooner due dates first if start dates are equal', function(){
          expect(this.children.indexOf(this.peBWithDates)).to.be.above(this.children.indexOf(this.peCWithDates));
        });
      });
    });

    describe('hasChildren', function () {
      it('should return false for hasChildren if children list undefined', function () {
        expect(this.peEmpty.hasChildren()).to.be.falsy;
      });
      it('should return false for hasChildren if children list empty', function () {
        var pe = Factory.build("PlanningElement", {
          planning_elements: []
        });

        expect(pe.hasChildren()).to.be.falsy;
      });
      it('should return true for hasChildren if children exist', function () {
        expect(this.peWithChildren.hasChildren()).to.be.truthy;
      });
    });
  });

  describe('hide', function () {
    it('should always return false', function () {
      expect(this.peEmpty.hide()).to.be.false;
    });
  });

  describe('getProject', function () {
    it('should be null by default', function () {
      expect(this.peEmpty.getProject()).to.be.null;
    });
    it('should be the set project otherwise', function () {
      var pe = Factory.build("PlanningElement", {
        project: "TestProjekt"
      });
      expect(pe.getProject()).to.equal("TestProjekt");
    });
  });

  describe('filtered out', function () {
    it('should only be filtered if project is filtered');
    it('should cache the result even if filter changes');
  });

  describe('responsible', function () {
    it('should be null by default', function () {
      expect(this.peEmpty.getResponsible()).to.be.null;
    });
    it('should get the responsible');
    it('should allow get of responsible name');
    it('should return undefined if responsible or responsible name are not set');
  });

  describe('assignee name', function () {
    it('should be undefined by default', function () {
      expect(this.peEmpty.getAssignedName()).to.be.undefined;
    });
    it('should allow get of assignee name', function () {
      var pe = Factory.build("PlanningElement", {
        assigned_to: {
          name: "Hannibal"
        }
      });
      expect(pe.getAssignedName()).to.equal("Hannibal");
    });
    it('should return undefined if invalid assigned to object', function () {
      var pe = Factory.build("PlanningElement", {
        assigned_to: {}
      });
      expect(pe.getAssignedName()).to.be.undefined;
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
      peWithHistorical = Factory.build("PlanningElement", {
        historical_element: this.peWithDates
      });

      expect(peWithHistorical.hasAlternateDates()).to.be.true;
      expect(peWithHistorical.alternate_start().getTime()).to.equal(1352588400*1000);
      expect(peWithHistorical.alternate_end().getTime()).to.equal(1352674800*1000);
    });
  });

  describe('getAttribute', function () {
    it('should return object value of object.parameter', function () {
      var pe = Factory.build("PlanningElement", {test: "5829468972w4"});
      expect(pe.getAttribute("test")).to.equal("5829468972w4");
    });
    it('should return function value of object.parameter', function () {
      var pe = Factory.build("PlanningElement", {project: "4z3t078nzg098"});
      expect(pe.getAttribute("getProject")).to.equal("4z3t078nzg098");
    });
  });

  describe('horizontalBoundsForDates', function () {
    function expectBoundary(boundary, x, w, end) {
      expect(boundary.x).to.equal(x);
      expect(boundary.w).to.equal(w);
      expect(boundary.end()).to.equal(end);
    }

    var beginning = new Date("2012-11-13");
    var scale = {day: 1};

    it('should return 0 for x and width if no start&end date', function () {
      var boundary = this.peEmpty.getHorizontalBounds();
      expect(boundary.x).to.equal(0);
      expect(boundary.w).to.equal(0);
      expect(boundary.end()).to.equal(0);
    });
    it('should return zero x if beginning and start are the same', function () {
      var absolute_beginning = this.peWithDates.start();

      var boundary = this.peWithDates.getHorizontalBounds(scale, absolute_beginning);
      expect(boundary.x).to.equal(0);
    });
    it('should return width of 1 day if start and end are equal', function () {
      var sameDatePE = Factory.build("PlanningElement", {
        timeline: Factory.build("Timeline"),
        start_date: "2012-11-11",
        due_date: "2012-11-11"
      });

      var boundary = sameDatePE.getHorizontalBounds(scale, beginning);

      expect(boundary.w).to.equal(1);
    });
    it('should return width of difference+1 if start and end are not the same', function () {
      var differentDatePE = Factory.build("PlanningElement", {
        timeline: Factory.build("Timeline"),
        start_date: "2012-11-11",
        due_date: "2012-11-15"
      });

      var boundary = differentDatePE.getHorizontalBounds(scale, beginning);

      expect(boundary.w).to.equal(5);
    });
    it('should multiply with scale', function () {
      var scale = {day: 5};

      var differentDatePE = Factory.build("PlanningElement", {
        timeline: Factory.build("Timeline"),
        start_date: "2012-11-19",
        due_date: "2012-11-23"
      });

      var boundary = differentDatePE.getHorizontalBounds(scale, beginning);
      expectBoundary(boundary, 30, 25, 55);
    });
    it('if one date is not set width equals 3 days', function () {
      var noStartDatePE = Factory.build("PlanningElement", {
        timeline: Factory.build("Timeline"),
        due_date: "2012-11-15"
      });

      var boundary = noStartDatePE.getHorizontalBounds(scale, beginning);
      expectBoundary(boundary, 0, 3, 3);
    });
    it('should return x and width if end is not set', function () {
      var noEndDatePE = Factory.build("PlanningElement", {
        timeline: Factory.build("Timeline"),
        start_date: "2012-11-13"
      });

      boundary = noEndDatePE.getHorizontalBounds(scale, beginning);
      expectBoundary(boundary, 0, 3, 3);
    });
    it('should return the middle for a milestone');
  });

  describe('url', function () {
    it('should return correct url', function () {
      var pe = Factory.build("PlanningElement", {
        timeline: Factory.build("Timeline", {}, {url_prefix: "/vtu"}),
        id: 9991
      });
      expect(pe.getUrl()).to.equal("/vtu/work_packages/9991");
    });
  });

  describe('color', function () {
    it('should return color of pe type if existing');
    it('should return parent color if pe has children');
    it('should return default color for empty pe');
    it('should return gradient if one date is missing');
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
      expect(this.peWithDates.end().getTime()).to.equal(1352674800*1000);
    });

    it('should return undefined for no date' , function () {
      expect(this.peEmpty.start()).to.not.exist;
      expect(this.peEmpty.end()).to.not.exist;

      expect(this.peEmpty.hasStartDate()).to.be.false;
      expect(this.peEmpty.hasEndDate()).to.be.false;
      expect(this.peEmpty.hasBothDates()).to.be.false;
      expect(this.peEmpty.hasOneDate()).to.be.false;
    });

    it('should return end date for start() if no end date is set and is milestone');
    it('should return start date for end() if no start date is set and is milestone');
  });
});
