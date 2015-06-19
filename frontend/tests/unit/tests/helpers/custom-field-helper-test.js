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

/*jshint expr: true*/

describe('Custom field helper', function() {
  var CustomFieldHelper;

  beforeEach(module('openproject.helpers'));
  beforeEach(inject(function(_CustomFieldHelper_) {
    CustomFieldHelper = _CustomFieldHelper_;
  }));

  describe('formatCustomFieldValue', function() {
    var formatCustomFieldValue;

    beforeEach(function() {
      formatCustomFieldValue = CustomFieldHelper.formatCustomFieldValue;
    });

    describe('with a boolean type', function() {
      var I18n, t;

      beforeEach(inject(function(_I18n_){
        I18n = _I18n_;
        t = sinon.stub(I18n, 't');
        t.withArgs('js.general_text_No').returns('No');
        t.withArgs('js.general_text_Yes').returns('Yes');
      }));

      afterEach(inject(function() {
        I18n.t.restore();
      }));

      it('should handle undefined and null values', function() {
        expect(formatCustomFieldValue(null,      'bool')).to.not.be.ok;
        expect(formatCustomFieldValue(undefined, 'bool')).to.not.be.ok;
      });

      it('should parse a false value', function() {
        expect(formatCustomFieldValue('0', 'bool')).to.equal('No');
      });

      it('should parse a true value', function() {
        expect(formatCustomFieldValue('1', 'bool')).to.equal('Yes');
      });
    });

    describe('with an integer type', function() {
      it('should handle undefined and null values', function() {
        expect(formatCustomFieldValue(null,      'int')).to.equal('');
        expect(formatCustomFieldValue(undefined, 'int')).to.equal('');
      });

      it('should parse a float, displaying as integer', function() {
        expect(formatCustomFieldValue(200000.49, 'int')).to.equal(200000);
        expect(formatCustomFieldValue(200000.51, 'int')).to.equal(200000);
      });

      it('should parse a string, displaying as integer', function() {
        expect(formatCustomFieldValue('49',      'int')).to.equal(49);
        expect(formatCustomFieldValue('49.99',   'int')).to.equal(49);
        expect(formatCustomFieldValue('49.BLAH', 'int')).to.equal('');
      });

      it('should preserve an integer', function() {
        expect(formatCustomFieldValue(49, 'int')).to.equal(49);
      });

      it('should handle a meaningless string', function() {
        expect(formatCustomFieldValue('BLAHBLAH','int')).to.equal('');
      });
    });

    describe('with a float type', function() {
      it('should handle undefined and null values', function() {
        expect(formatCustomFieldValue(null,      'int')).to.equal('');
        expect(formatCustomFieldValue(undefined, 'int')).to.equal('');
      });

      xit('should parse an integer, displaying with decimal places', function() {
        expect(formatCustomFieldValue(99, 'float')).to.equal(99);
      });

      it('should parse a string, displaying as float', function() {
        expect(formatCustomFieldValue('49.99',    'float')).to.equal(49.99);
        expect(formatCustomFieldValue('49.99BLAH','float')).to.equal('');
      });

      it('should preserve a float', function() {
        expect(formatCustomFieldValue(11.11, 'float')).to.equal(11.11);
      });

      it('should handle a meaningless string', function() {
        expect(formatCustomFieldValue('BLAHBLAH','int')).to.equal('');
      });
    });

    describe('with a user type', function() {
      it('should return the value of value.name', function() {
        expect(formatCustomFieldValue({ name: 'blubs' }, 'user')).to.equal('blubs');
      });

      it('should handle undefined and null values', function() {
        expect(formatCustomFieldValue(undefined, 'user')).to.equal('');
        expect(formatCustomFieldValue(null, 'user')).to.equal('');
        expect(formatCustomFieldValue({ name: undefined }, 'user')).to.equal('');
        expect(formatCustomFieldValue({ name: null }, 'user')).to.equal('');
      });

      it('should return the name of the user out of a list of provided users', function() {
        expect(formatCustomFieldValue( 5 , 'user', { '5': { name: 'blubs' }})).to.equal('blubs');
      });

      it('should return empty string if the user does' +
         'not exists in list of provided users', function() {
        expect(formatCustomFieldValue( 4 , 'user', { '5': { name: 'blubs' }})).to.equal('');
      });

      it('should handle undefined and null values in list of provided users', function() {
        expect(formatCustomFieldValue( 5 , 'user', { '5': { name: null }})).to.equal('');
        expect(formatCustomFieldValue( 5 , 'user', { '5': { name: undefined }})).to.equal('');
        expect(formatCustomFieldValue( 5 , 'user', { '5': undefined })).to.equal('');
        expect(formatCustomFieldValue( 5 , 'user', { '5': null })).to.equal('');
      });
    });

    describe('with a version type', function() {
      it('should return the value of value.name', function() {
        expect(formatCustomFieldValue({ name: 'blubs' }, 'version')).to.equal('blubs');
      });

      it('should handle undefined and null values', function() {
        expect(formatCustomFieldValue(undefined, 'version')).to.equal('');
        expect(formatCustomFieldValue(null, 'version')).to.equal('');
        expect(formatCustomFieldValue({ name: undefined }, 'version')).to.equal('');
        expect(formatCustomFieldValue({ name: null }, 'version')).to.equal('');
      });
    });
  });
});