// -- copyright
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
// ++

describe('EditableFieldsState service', function () {
  var EditableFieldsState, eAll;

  beforeEach(angular.mock.module('openproject.services', 'openproject.workPackages.services'));

  beforeEach(inject(function (_EditableFieldsState_) {
    EditableFieldsState = _EditableFieldsState_;
  }));

  describe('is active field method', function () {
    var field = 'my_field', other = 'other_field';

    beforeEach(function () {
      EditableFieldsState.currentField = field;
    });

    it('checks if the given field is active or not', function () {
      expect(EditableFieldsState.isActiveField(field)).to.be.true;
      expect(EditableFieldsState.isActiveField(other)).to.be.false;
    });

    it('returns false if editAll.state or forcedEditState are set', function () {
      EditableFieldsState.editAll.state = true;
      EditableFieldsState.forcedEditState = true;
      expect(EditableFieldsState.isActiveField(field)).to.be.false;
    });
  });

  describe('edit all', function () {
    beforeEach(function () {
      EditableFieldsState.workPackage = { links: {} };
      eAll = EditableFieldsState.editAll;
    });

    it('toggle state switches its current state', function () {
      expect(EditableFieldsState.state === eAll.toggleState()).to.be.false;
    });

    it('turns on editing on start', function () {
      expect(eAll.start()).to.be.true;
    });

    it('turns off editing on stop', function () {
      expect(eAll.stop()).to.be.false;
    });

    it('matches its focused field', function () {
      expect(eAll.isFocusField(eAll.focusField)).to.be.true;
    });

    it('is allowed if the WP update action is defined', function () {
      EditableFieldsState.workPackage.links.update = 'something';
      expect(eAll.allowed).to.be.true;
    });

    it('is not allowed if th WP update action does not exist', function () {
      expect(eAll.allowed).to.be.false;
    });
  });
});
