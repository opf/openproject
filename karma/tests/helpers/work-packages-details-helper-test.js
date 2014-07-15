//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe('Work packages details helper', function() {
  var WorkPackagesDetailsHelper;
  beforeEach(module('openproject.helpers'));
  beforeEach(inject(function(_WorkPackagesDetailsHelper_) {
    WorkPackagesDetailsHelper = _WorkPackagesDetailsHelper_;
  }));

  describe('attachmentDisplayName', function() {
    var attachmentDisplayName;
    beforeEach(function() {
      attachmentDisplayName = WorkPackagesDetailsHelper.attachmentDisplayName;
    });

    it('should format the file size in kB', function() {
      var attachment = {
        props: { fileSize: '1234', fileName: 'massive.txt' }
      };

      expect(attachmentDisplayName(attachment)).to.equal('massive.txt (1.23kB)');
    });

    it('should show zero file size', function() {
      var attachment = {
        props: { fileName: 'prawns.txt' }
      };

      expect(attachmentDisplayName(attachment)).to.equal('prawns.txt (0kB)');
    });
  });

  describe('attachmentsTitle', function() {
    var attachmentsTitle;
    beforeEach(function() {
      attachmentsTitle = WorkPackagesDetailsHelper.attachmentsTitle;
    });

    it('should show count in title', function() {
      var attachments = [
        {props: { fileName: 'smell.txt' }},
        {props: { fileName: 'my.txt' }},
        {props: { fileName: 'cheese.txt' }}];

      expect(attachmentsTitle(attachments)).to.equal('Attachments (3)');
    });
  });
});
