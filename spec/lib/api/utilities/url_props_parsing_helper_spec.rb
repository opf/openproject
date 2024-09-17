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

RSpec.describe API::Utilities::UrlPropsParsingHelper do
  let(:clazz) do
    Class.new do
      include API::Utilities::UrlPropsParsingHelper
    end
  end
  let(:subject) { clazz.new }

  describe "#maximum_page_size" do
    context "when small values in per_page_options",
            with_settings: { per_page_options: "20,100", apiv3_max_page_size: 57 } do
      it "uses the value from settings" do
        expect(subject.maximum_page_size).to eq(57)
      end
    end

    context "when larger values in per_page_options",
            with_settings: { per_page_options: "20,100,1000", apiv3_max_page_size: 57 } do
      it "uses that value" do
        expect(subject.maximum_page_size).to eq(57)
      end
    end
  end
end
