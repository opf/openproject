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

var expect = require('../../../spec_helper.js').expect,
    detailsPaneHelper = require('./details-pane-helper.js');

/*jshint expr: true*/

describe('OpenProject', function() {
  describe('pane itself', function() {
    beforeEach(function() {
      detailsPaneHelper.loadPane(819, 'overview');
    });

    it('should be visible', function() {
      expect($('.work-packages--details').isPresent()).to.eventually.be.true;
    });
  });

  describe('activities', function() {
    describe('overview tab', function() {
      before(function() {
        detailsPaneHelper.loadPane(819, 'overview');
      });

      describe('custom fields order', function() {
        before(function() {
          detailsPaneHelper.showAll();
        });

        it('is enforced', function() {
          var textPromises = element.all(by.css('.attributes-key-value--key')).map(function(el) {
            return el.getText();
          });

          textPromises.then(function(texts) {
            var sortedTexts = texts.sort(function(a, b) {
              return a.localeCompare(b);
            });

            expect(texts).to.eq(sortedTexts);
          });
        });
      });

      describe('activities', function() {
        it('should render the last 3 activites', function() {
          expect(
            $('ul li:nth-child(1) div.comments-number').getText()
          ).to.eventually.equal('#3');

          expect(
            $('ul li:nth-child(2) div.comments-number').getText()
          ).to.eventually.equal('#2');

          expect(
            $('ul li:nth-child(3) div.comments-number').getText()
          ).to.eventually.equal('#1');
        });

        it('should contain the activities details', function() {
          expect(
            $('ul.work-package-details-activities-messages li:nth-child(1) .message').getText()
          ).to.eventually.equal('Status changed from new to in progress');
        });
      });
    });
  });
});
