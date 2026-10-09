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
require_relative "expected_markdown"

RSpec.describe OpenProject::TextFormatting, "horizontal rules" do # rubocop:disable RSpec/SpecFilePathFormat
  include_context "expected markdown modules"

  let(:expected) do
    <<~EXPECTED
      <p class="op-uc-p">First slide</p>
      <hr>
      <p class="op-uc-p">Second slide</p>
    EXPECTED
  end

  context "with dashes" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          First slide

          ---

          Second slide
        RAW
      end
    end
  end

  context "with asterisks" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          First slide

          ***

          Second slide
        RAW
      end
    end
  end

  context "with spaced asterisks as serialized by CKEditor" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          First slide

          * * *

          Second slide
        RAW
      end
    end
  end

  context "with an HTML hr tag" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          First slide

          <hr />

          Second slide
        RAW
      end
    end
  end
end
