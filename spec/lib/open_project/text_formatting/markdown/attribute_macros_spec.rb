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

RSpec.describe OpenProject::TextFormatting,
               "Attribute macros" do
  include_context "expected markdown modules"

  describe "attribute label macros" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          # My headline

          Inline reference to WP by ID: workPackageLabel:1234:subject

          Inline reference to WP by subject: workPackageLabel:"Some subject":"Some custom field with spaces"

          Inline reference to project: projectLabel:status

          Inline reference to project with id: projectLabel:"some id":status
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <h1 class="op-uc-h1" id="my-headline">
            My headline
            <a class="op-uc-link_permalink icon-link op-uc-link" aria-hidden="true" href="#my-headline"></a>
          </h1>
          <p class="op-uc-p">
            Inline reference to WP by ID: <opce-macro-attribute-label data-model="workPackage" data-id="1234" data-attribute="subject"></opce-macro-attribute-label>
          </p>
          <p class="op-uc-p">
            Inline reference to WP by subject: <opce-macro-attribute-label data-model="workPackage" data-id="Some subject" data-attribute="Some custom field with spaces"></opce-macro-attribute-label>
          </p>
          <p class="op-uc-p">
            Inline reference to project: <opce-macro-attribute-label data-model="project" data-attribute="status"></opce-macro-attribute-label>
          </p>
          <p class="op-uc-p">
            Inline reference to project with id: <opce-macro-attribute-label data-model="project" data-id="some id" data-attribute="status"></opce-macro-attribute-label>
          </p>
        EXPECTED
      end
    end
  end

  describe "attribute value macros" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          # My headline

          Inline reference to WP by ID: workPackageValue:1234:subject

          Inline reference to WP by subject: workPackageValue:"Some subject":"Some custom field with spaces"

          Inline reference to project: projectValue:status

          Inline reference to project with id: projectValue:"some id":status
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <h1 class="op-uc-h1" id="my-headline">
            My headline
            <a class="op-uc-link_permalink icon-link op-uc-link" aria-hidden="true" href="#my-headline"></a>
          </h1>
          <p class="op-uc-p">
            Inline reference to WP by ID: <opce-macro-attribute-value data-model="workPackage" data-id="1234" data-attribute="subject"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Inline reference to WP by subject: <opce-macro-attribute-value data-model="workPackage" data-id="Some subject" data-attribute="Some custom field with spaces"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Inline reference to project: <opce-macro-attribute-value data-model="project" data-attribute="status"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Inline reference to project with id: <opce-macro-attribute-value data-model="project" data-id="some id" data-attribute="status"></opce-macro-attribute-value>
          </p>
        EXPECTED
      end
    end
  end
end
