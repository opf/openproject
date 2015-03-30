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

describe('ParentRelationsHandler', function() {
  var ParentRelationsHandler,
      relationsHandler,
      workPackage;

  beforeEach(module('openproject'));

  beforeEach(inject(function($injector) {
    ParentRelationsHandler = $injector.get('ParentRelationsHandler');
  }));

  beforeEach(function() {
    workPackage = {
      links: {
        delete: { href: 'deleteMeLink' },
        update: { href: 'updateMeLink' },
        log_time: { href: 'log_timeMeLink' },
      },
      props: {
        id: 20
      }
    };
  });

  describe('initializing', function() {
    it('does not contain itself in relations', function() {
      var relations = [{
        props: {
          id: 20
        }
      }];
      relationsHandler = new ParentRelationsHandler(workPackage, relations, 'parent');

      expect(relationsHandler.relations.length).to.eq(0);
    });

    it('does contains only parents not itself', function() {
      var relations = [{
        props: {
          id: 20
        }
      }, {
        props: {
          id: 21
        }
      }];
      relationsHandler = new ParentRelationsHandler(workPackage, relations, 'parent');

      expect(relationsHandler.relations.length).to.eq(1);
      expect(relationsHandler.relations[0].props.id).to.eq(21);
    });
  });
});
