# frozen_string_literal: true

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

RSpec.describe ExternalLink do
  describe "validations" do
    subject(:external_link) { build(:external_link, url:) }

    context "without a URL" do
      let(:url) { "" }

      it "is invalid" do
        expect(external_link).not_to be_valid
        expect(external_link.errors.details[:url]).to include(error: :blank)
      end
    end

    context "with a value that is not an http(s) URL" do
      let(:url) { "not a url" }

      it "is valid" do
        expect(external_link).to be_valid
      end
    end

    context "without a work package" do
      subject(:external_link) { build(:external_link, work_package: nil) }

      it "is invalid" do
        expect(external_link).not_to be_valid
        expect(external_link.errors.details[:work_package]).to include(error: :blank)
      end
    end
  end

  describe "normalization" do
    subject(:external_link) do
      build(:external_link,
            url: " https://example.com/plan ",
            title: " Release plan ",
            description: "First line\r\nSecond line\n",
            application_type: "")
    end

    it "strips surrounding whitespace, converts Windows line breaks and stores blank values as nil" do
      expect(external_link).to have_attributes(url: "https://example.com/plan",
                                               title: "Release plan",
                                               description: "First line\nSecond line",
                                               application_type: nil)
    end
  end

  context "when its work package is destroyed" do
    let(:external_link) { create(:external_link) }

    before { external_link.work_package.destroy }

    it "is deleted" do
      expect(described_class).not_to exist(external_link.id)
    end
  end
end
