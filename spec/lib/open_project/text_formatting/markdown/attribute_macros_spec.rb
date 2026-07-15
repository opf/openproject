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

RSpec.shared_examples_for "resolving macros" do
  describe "attribute label macros" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          # My headline

          Inline reference to WP: workPackageLabel:subject

          Inline reference to WP by ID: workPackageLabel:1234:subject

          Inline reference to WP by ID with CF with a dot: workPackageLabel:1234:"1. test"

          Inline reference to WP by subject: workPackageLabel:"Some subject":"Some custom field with spaces"

          Inline reference to project: projectLabel:status

          Inline reference to project with id: projectLabel:4321:status

          Inline reference to project with name: projectLabel:"some name":status
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <h1 class="op-uc-h1" id="op-frag-my-headline">
            My headline
            <a class="op-uc-link_permalink icon-link op-uc-link" aria-hidden="true" href="#op-frag-my-headline" rel="noopener noreferrer nofollow"></a>
          </h1>
          <p class="op-uc-p">
            Inline reference to WP: <opce-macro-attribute-label data-model="workPackage" data-id="1234" data-attribute="subject"></opce-macro-attribute-label>
          </p>
          <p class="op-uc-p">
            Inline reference to WP by ID: <opce-macro-attribute-label data-model="workPackage" data-id="1234" data-attribute="subject"></opce-macro-attribute-label>
          </p>
          <p class="op-uc-p">
            Inline reference to WP by ID with CF with a dot: <opce-macro-attribute-label data-model="workPackage" data-id="1234" data-attribute="1. test"></opce-macro-attribute-label>
          </p>
          <p class="op-uc-p">
            Inline reference to WP by subject: <opce-macro-attribute-label data-model="workPackage" data-id="Some subject" data-attribute="Some custom field with spaces"></opce-macro-attribute-label>
          </p>
          <p class="op-uc-p">
            Inline reference to project: <opce-macro-attribute-label data-model="project" data-id="4321" data-attribute="status"></opce-macro-attribute-label>
          </p>
          <p class="op-uc-p">
            Inline reference to project with id: <opce-macro-attribute-label data-model="project" data-id="4321" data-attribute="status"></opce-macro-attribute-label>
          </p>
          <p class="op-uc-p">
            Inline reference to project with name: <opce-macro-attribute-label data-model="project" data-id="some name" data-attribute="status"></opce-macro-attribute-label>
          </p>
        EXPECTED
      end
    end
  end

  describe "attribute value macros with layout argument" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          Explicit multi-line: workPackageValue:1234:targetVersions:multiline

          Explicit single-line: workPackageValue:1234:targetVersions:singleline

          Quoted custom field with layout: workPackageValue:1234:"My list field":singleline

          Relative reference with layout: workPackageValue:targetVersions:singleline

          Relative quoted custom field with layout: workPackageValue:"My list field":singleline

          Unknown keyword is not a layout: workPackageValue:1234:targetVersions:block

          Bare layout keyword after an id reads as relative reference plus layout: workPackageValue:1234:singleline

          Quoted layout keyword stays an attribute name: workPackageValue:1234:"singleline"
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">
            Explicit multi-line: <opce-macro-attribute-value data-model="workPackage" data-id="1234" data-attribute="targetVersions" data-layout="multiline"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Explicit single-line: <opce-macro-attribute-value data-model="workPackage" data-id="1234" data-attribute="targetVersions" data-layout="singleline"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Quoted custom field with layout: <opce-macro-attribute-value data-model="workPackage" data-id="1234" data-attribute="My list field" data-layout="singleline"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Relative reference with layout: <opce-macro-attribute-value data-model="workPackage" data-id="1234" data-attribute="targetVersions" data-layout="singleline"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Relative quoted custom field with layout: <opce-macro-attribute-value data-model="workPackage" data-id="1234" data-attribute="My list field" data-layout="singleline"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Unknown keyword is not a layout: <opce-macro-attribute-value data-model="workPackage" data-id="1234" data-attribute="targetVersions"></opce-macro-attribute-value>:block
          </p>
          <p class="op-uc-p">
            Bare layout keyword after an id reads as relative reference plus layout: <opce-macro-attribute-value data-model="workPackage" data-id="1234" data-attribute="1234" data-layout="singleline"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Quoted layout keyword stays an attribute name: <opce-macro-attribute-value data-model="workPackage" data-id="1234" data-attribute="singleline"></opce-macro-attribute-value>
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

          Inline reference to WP: workPackageValue:subject

          Inline reference to WP by ID: workPackageValue:1234:subject

          Inline reference to WP by subject: workPackageValue:"Some subject":"Some custom field with spaces"

          Inline reference to project: projectValue:status

          Inline reference to project with id: projectValue:4321:status

          Inline reference to project with name: projectValue:"some name":status
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <h1 class="op-uc-h1" id="op-frag-my-headline">
            My headline
            <a class="op-uc-link_permalink icon-link op-uc-link" aria-hidden="true" href="#op-frag-my-headline" rel="noopener noreferrer nofollow"></a>
          </h1>
          <p class="op-uc-p">
            Inline reference to WP: <opce-macro-attribute-value data-model="workPackage" data-id="1234" data-attribute="subject"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Inline reference to WP by ID: <opce-macro-attribute-value data-model="workPackage" data-id="1234" data-attribute="subject"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Inline reference to WP by subject: <opce-macro-attribute-value data-model="workPackage" data-id="Some subject" data-attribute="Some custom field with spaces"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Inline reference to project: <opce-macro-attribute-value data-model="project" data-id="4321" data-attribute="status"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Inline reference to project with id: <opce-macro-attribute-value data-model="project" data-id="4321" data-attribute="status"></opce-macro-attribute-value>
          </p>
          <p class="op-uc-p">
            Inline reference to project with name: <opce-macro-attribute-value data-model="project" data-id="some name" data-attribute="status"></opce-macro-attribute-value>
          </p>
        EXPECTED
      end
    end
  end
end

RSpec.describe OpenProject::TextFormatting, "Attribute macros" do
  include_context "expected markdown modules"
  shared_let(:project) { create(:valid_project, id: 4321) }
  let(:work_package) { create(:work_package, project:, id: 1234) }

  context "with work package" do
    it_behaves_like "resolving macros" do
      let(:options) { { project:, object: work_package } }
    end
  end

  context "with eager loading work package wrapper" do
    it_behaves_like "resolving macros" do
      let(:options) do
        {
          project:,
          object: API::V3::WorkPackages::WorkPackageEagerLoadingWrapper.wrap_one(work_package, nil)
        }
      end
    end
  end
end
