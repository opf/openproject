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

describe VersionsHelper, type: :helper do
  include ApplicationHelper

  let(:test_project) { FactoryBot.build_stubbed :valid_project }
  let(:version) { FactoryBot.build_stubbed :version, project: test_project }

  describe '#format_version_name' do
    context 'a version' do
      it 'can be formatted' do
        expect(format_version_name(version)).to eq("#{test_project.name} - #{version.name}")
      end

      it 'can be formatted within a project' do
        @project = test_project
        expect(format_version_name(version)).to eq(version.name)
      end
    end

    context 'a system version' do
      let(:version) { FactoryBot.build_stubbed :version, project: test_project, sharing: 'system' }

      it 'can be formatted' do
        expect(format_version_name(version)).to eq("#{test_project.name} - #{version.name}")
      end
    end
  end

  describe '#link_to_version' do
    context 'a version' do
      context 'with being allowed to see the version' do
        it 'does not create a link, without permission' do
          expect(link_to_version(version)).to eq("#{test_project.name} - #{version.name}")
        end
      end

      describe 'with a user being allowed to see the version' do
        before do
          allow(version)
            .to receive(:visible?)
            .and_return(true)
        end

        it 'generates a link' do
          expect(link_to_version(version)).to eq("<a href=\"/versions/#{version.id}\">#{test_project.name} - #{version.name}</a>")
        end

        it 'generates a link within a project' do
          @project = test_project
          expect(link_to_version(version)).to eq("<a href=\"/versions/#{version.id}\">#{version.name}</a>")
        end
      end
    end

    describe 'an invalid version' do
      let(:version) { Object }

      it 'does not generate a link' do
        expect(link_to_version(Object)).to be_empty
      end
    end
  end

  describe '#version_options_for_select' do
    it 'generates nothing without a version' do
      expect(version_options_for_select([])).to be_empty
    end

    it 'generates an option tag' do
      expect(version_options_for_select([], version)).to eq("<option selected=\"selected\" value=\"#{version.id}\">#{version.name}</option>")
    end
  end
end
