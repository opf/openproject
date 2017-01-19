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

describe('Filter', function () {
  var Filter;

  beforeEach(angular.mock.module('openproject.filters'));
  beforeEach(angular.mock.inject(function (_Filter_) {
    Filter = _Filter_;
  }));

  it('should exist', function () {
    expect(Filter).to.exist;
  });

  it('should be a constructor function', function () {
    expect(new Filter()).to.exist;
    expect(new Filter()).to.be.an('object');
  });

  it('should be serializable to params', function () {
    var filter = Factory.build('Filter');
    var params = filter.toParams();

    expect(params).to.have.property('op[type_id]').and.equal('~');
    expect(params).to.have.property('v[type_id][]').and.contain('Bug');
  });

  describe('when it is a single input filter', function () {
    var filter, textValue;

    describe('with newly created instances', function() {
      beforeEach(function () {
        filter = Factory.build('Filter', {name: 'subject', type: 'string', values: []});
        textValue = 'abc';
        filter.textValue = textValue;
      });

      it('the text value is set', function () {
        expect(filter.textValue).to.be.eql(textValue);
      });

      it('is considered to be configured', function () {
        expect(filter.isConfigured()).to.be.true;
      });

      it('should serialize the text value', function () {
        expect(filter.getValuesAsArray()).to.eql([textValue]);
      });
    });

    describe('with instances restored from existing query', function () {
      beforeEach(function () {
        textValue = 'abc';
        filter = Factory.build('Filter', {name: 'subject', type: 'string', values: [textValue]});
      });

      it('the text value is set', function () {
        expect(filter.textValue).to.be.eql(textValue);
      });
    });
  });

  describe('single date filter', function () {
    var filter, dateValue;

    describe('with newly created instances', function () {
      beforeEach(function () {
        filter = Factory.build('Filter', {name: 'createdAt', type: 'date', operator: '=d', values: []});
        dateValue = '2016-12-01';
        filter.dateValue = dateValue;
      });

      it('is considered to be configured', function () {
        expect(filter.isConfigured()).to.be.true;
      });

      it('should serialize the date value', function () {
        expect(filter.getValuesAsArray()).to.eql([dateValue]);
      });
    });

    describe('with instances restored from existing query', function () {
      beforeEach(function () {
        dateValue = '2016-12-01';
        filter = Factory.build('Filter', {name: 'createdAt', type: 'date', operator: '=d', values: [dateValue]});
      });

      it('date value is set', function () {
        expect(filter.dateValue).to.eql(dateValue);
      });
    });
  });

  describe('date range filter', function () {
    var filter, dateValues;

    describe('with newly created instances', function () {
      beforeEach(function () {
        filter = Factory.build('Filter', {name: 'createdAt', type: 'date', operator: '<>d', values: []});
      });

      it('#isConfigured() returns a boolean', function () {
        expect(typeof filter.isConfigured()).to.eql('boolean');
      });

      describe('and the values are set incl. both from and until', function () {
        beforeEach(function () {
          dateValues = ['2016-12-01', '2016-12-31'];
          filter.values = {'0': dateValues[0], '1': dateValues[1]};
        });

        it('is considered to be configured', function () {
          expect(filter.isConfigured()).to.be.true;
        });

        it('should serialize the date values', function () {
          expect(filter.getValuesAsArray()).to.eql(dateValues);
        });
      });

      describe('and the values are set incl. from excl. until', function () {
        beforeEach(function () {
          dateValues = ['2016-12-01'];
          filter.values = {'0': dateValues[0], '1': dateValues[1]};
        });

        it('is considered to be configured', function () {
          expect(filter.isConfigured()).to.be.true;
        });

        it('should serialize the date values', function () {
          expect(filter.getValuesAsArray()).to.eql(dateValues);
        });
      });

      describe('and the values are set excl. from incl. until', function () {
        beforeEach(function () {
          dateValues = ['undefined', '2016-12-31'];
          filter.values = {'0': dateValues[0], '1': dateValues[1]};
        });

        it('is considered to be configured', function () {
          expect(filter.isConfigured()).to.be.true;
        });

        it('should serialize the date values', function () {
          expect(filter.getValuesAsArray()).to.eql(dateValues);
        });
      });
    });

    describe('with instances restored from existing query', function () {
      beforeEach(function () {
        dateValues = ['2016-12-01', '2016-12-31'];
        filter = Factory.build('Filter', {name: 'createdAt', type: 'date', operator: '<>d', values: dateValues});
      });

      it('values is set and is a hash', function () {
        expect(filter.values).to.eql({'0':dateValues[0], '1':dateValues[1]});
      });
    });
  });
});
