//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
// See docs/COPYRIGHT.rdoc for more details.
//++

/*jshint expr: true*/

import {HookService} from "core-app/modules/plugins/hook-service";

describe('HookService', function() {
  let service = new HookService();

  var callback:any, invalidCallback:any;
  var validId = 'myValidCallbacks';

  var shouldBehaveLikeEmptyResult = function(id:string) {
    it('returns empty results', function() {
      expect(service.call(id)).to.be.empty;
    });
  };

  var shouldBehaveLikeResultWithElements = function(id:string, count:number) {
    it('returns #count results', function() {
      expect(service.call(id).length).to.eq(count);
    });
  };

  var shouldBehaveLikeCalledCallback = function(id:string) {
    beforeEach(function() {
      service.call(id);
    });

    it('is called', function() {
      expect(callback.called).to.be.true;
    });
  };

  var shouldBehaveLikeUncalledCallback = function(id:string) {
    beforeEach(function() {
      service.call(id);
    });

    it('is not called', function() {
      expect(invalidCallback.called).to.be.false;
    });
  };

  describe('register', function() {
    var invalidId = 'myInvalidCallbacks';

    describe('no callback registered', function() {
      shouldBehaveLikeEmptyResult(invalidId);
    });

    describe('non function callback registered', function() {
      beforeEach(function() {
        service.register('myInvalidCallbacks', 'eeek');
      });

      shouldBehaveLikeEmptyResult(invalidId);
    });

    describe('valid function callback registered', function() {
      beforeEach(function() {
        callback = sinon.spy();
        service.register('myValidCallbacks', callback);
      });

      shouldBehaveLikeEmptyResult(validId);

      shouldBehaveLikeCalledCallback(validId);
    });
  });

  describe('call', function() {
    describe('function that returns undefined', function() {
      beforeEach(function() {
        callback = sinon.spy();
        service.register('myValidCallbacks', callback);
      });

      shouldBehaveLikeCalledCallback(validId);

      shouldBehaveLikeEmptyResult(validId);
    });

    describe('function that returns something that is not undefined', function() {
      beforeEach(function() {
        callback = sinon.stub();
        callback.returns({});

        service.register('myValidCallbacks', callback);
      });

      shouldBehaveLikeCalledCallback(validId);

      shouldBehaveLikeResultWithElements(validId, 1);
    });

    describe('function that returns something that is not undefined', function() {
      beforeEach(function() {
        callback = sinon.stub();
        callback.returns({});

        service.register('myValidCallbacks', callback);
      });

      shouldBehaveLikeCalledCallback(validId);

      shouldBehaveLikeResultWithElements(validId, 1);
    });

    describe('function that returns something that is not undefined', function() {
      beforeEach(function() {
        callback = siton.spy();
        invalidCallback = sinon.spy();

        service.register('myValidCallbacks', callback);

        service.register('myInvalidCallbacks', invalidCallback);
      });

      shouldBehaveLikeCalledCallback(validId);

      shouldBehaveLikeUncalledCallback(validId);
    });

    describe('function that returns something that is not undefined', function() {
      var callback1, callback2;

      beforeEach(function() {
        callback1 = sinon.stub();
        callback1.returns({});
        callback2 = sinon.stub();
        callback2.returns({});

        service.register('myValidCallbacks', callback1);
        service.register('myValidCallbacks', callback2);
      });

      shouldBehaveLikeResultWithElements(validId, 2);
    });
  });
});
