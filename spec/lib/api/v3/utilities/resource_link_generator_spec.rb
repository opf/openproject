#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe API::V3::Utilities::ResourceLinkGenerator do
  include ::API::V3::Utilities::PathHelper

  subject { described_class }
  describe ':make_link' do
    it 'supports work packages' do
      wp = FactoryBot.build_stubbed(:work_package)
      expect(subject.make_link wp).to eql api_v3_paths.work_package(wp.id)
    end

    it 'supports priorities' do
      prio = FactoryBot.build_stubbed(:priority)
      expect(subject.make_link prio).to eql api_v3_paths.priority(prio.id)
    end

    it 'supports statuses' do
      status = FactoryBot.build_stubbed(:status)
      expect(subject.make_link status).to eql api_v3_paths.status(status.id)
    end

    it 'supports the anonymous user' do
      user = FactoryBot.build_stubbed(:anonymous)
      expect(subject.make_link user).to eql api_v3_paths.user(user.id)
    end

    it 'returns nil for unsupported records' do
      record = FactoryBot.create(:custom_field)
      expect(subject.make_link record).to be_nil
    end

    it 'returns a string object for strings' do
      record = 'a string'
      expect(subject.make_link record).to eql "/api/v3/string_objects?value=a%20string"
    end

    it 'returns nil for non-AR types' do
      record = Object.new
      expect(subject.make_link record).to be_nil
    end
  end
end
