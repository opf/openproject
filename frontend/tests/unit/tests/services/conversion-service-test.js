//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

describe('ConversionService', function() {
  'use strict';
  var ConversionService;

  beforeEach(angular.mock.module('openproject.services'));

  beforeEach(inject(function(_ConversionService_){
    ConversionService = _ConversionService_;
  }));

  it('be able to turn bytes into KiloBytes', function() {
    var kiloBytes = ConversionService.kilobytes(1000);
    expect(kiloBytes).to.eql(1);
  });

  it('be able to turn bytes into MegaBytes', function() {
    var megabytes = ConversionService.megabytes(1000000);
    expect(megabytes).to.eql(1);
  });

  it('should dynamically convert bytes into Mega- and Kilobytes', function() {
    var result = ConversionService.fileSize(1000000);
    expect(result).to.eql('1MB');

    result = ConversionService.fileSize(1000);
    expect(result).to.eql('1kB');

    result = ConversionService.fileSize(1234);
    expect(result).to.eql('1.2kB');

    result = ConversionService.fileSize(1874234);
    expect(result).to.eql('1.9MB');
  });
});
