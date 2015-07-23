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

describe('NotificationsService', function() {
  var NotificationsService;

  beforeEach(module('openproject.services'));

  beforeEach(inject(function(_NotificationsService_){
    NotificationsService = _NotificationsService_;
  }));

  it('should be able to create notifications', function() {
    var notification = NotificationsService.add('message');

    expect(notification).to.eql({ message: 'message' });
  });

  it('should be able to create warnings', function() {
    var notification = NotificationsService.addWarning('warning!');

    expect(notification).to.eql({ message: 'warning!', type: 'warning' });
  });

  it('should throw an Error if trying to create an error without errors', function() {
    expect(function() {
      NotificationsService.addError('error!');
    }).to.throw(Error);
  });

  it('should throw an Error if trying to create an upload without uploads', function() {
    expect(function() {
      NotificationsService.addWorkPackageUpload('themUploads');
    }).to.throw(Error);
  });

  it('should be able to create error messages with errors', function() {
    var notification = NotificationsService.addError('a super cereal error', ['fooo', 'baarr']);
    expect(notification).to.eql({
      message: 'a super cereal error',
      errors: ['fooo', 'baarr'],
      type: 'error'
    });
  });

  it('should be able to create error messages with errors', function() {
    var notification = NotificationsService.addWorkPackageUpload('uploading...', [0, 1, 2]);
    expect(notification).to.eql({
      message: 'uploading...',
      type: 'upload',
      uploads: [0, 1, 2]
    });
  });
})
