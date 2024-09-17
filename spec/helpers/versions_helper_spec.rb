#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe VersionsHelper do
  include ApplicationHelper

  let(:test_project) { build_stubbed(:valid_project) }
  let(:version) { build_stubbed(:version, project: test_project) }

  describe "#format_version_name" do
    context "a version" do
      it "can be formatted" do
        expect(format_version_name(version)).to eq("#{test_project.name} - #{version.name}")
      end

      it "can be formatted within a project" do
        @project = test_project
        expect(format_version_name(version)).to eq(version.name)
      end
    end

    context "a system version" do
      let(:version) { build_stubbed(:version, project: test_project, sharing: "system") }

      it "can be formatted" do
        expect(format_version_name(version)).to eq("#{test_project.name} - #{version.name}")
      end
    end
  end

  describe "#link_to_version" do
    context "a version" do
      context "with being allowed to see the version" do
        it "does not create a link, without permission" do
          expect(link_to_version(version))
            .to eq("#{test_project.name} - #{version.name}")
        end
      end

      describe "with a user being allowed to see the version" do
        before do
          allow(version)
            .to receive(:visible?)
            .and_return(true)
        end

        it "generates a link" do
          expect(link_to_version(version))
            .to be_html_eql("<a href=\"/versions/#{version.id}\" id=\"version-#{ERB::Util.url_encode(version.name)}\">#{test_project.name} - #{version.name}</a>")
        end

        it "generates a link within a project" do
          @project = test_project
          expect(link_to_version(version))
            .to be_html_eql("<a href=\"/versions/#{version.id}\" id=\"version-#{ERB::Util.url_encode(version.name)}\">#{version.name}</a>")
        end
      end
    end

    describe "#link_to_version_id" do
      it "generates an escaped id" do
        expect(link_to_version_id(version))
          .to eql("version-#{ERB::Util.url_encode(version.name)}")
      end
    end
  end

  describe "#version_options_for_select" do
    it "generates nothing without a version" do
      expect(version_options_for_select([])).to be_empty
    end

    it "generates an option tag" do
      expect(version_options_for_select([],
                                        version)).to eq("<option selected=\"selected\" value=\"#{version.id}\">#{version.name}</option>")
    end
  end
end
