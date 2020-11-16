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

describe OpenProject::TextFormatting,
         'Attribute macros',
         # Speeds up the spec by avoiding event mailers to be processed
         with_settings: { notified_events: [] } do

  subject do
    ::OpenProject::TextFormatting::Renderer.format_text(raw)
  end

  describe 'attribute label macros' do
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
         <a class="wiki-anchor icon-paragraph" aria-hidden="true" href="#my-headline"></a>My headline
        </h1>
        <p class="op-uc-p">
          Inline reference to WP by ID: <macro class="macro--attribute-label" data-model="workPackage" data-id="1234" data-attribute="subject"></macro>
        </p>
        <p class="op-uc-p">
          Inline reference to WP by subject: <macro class="macro--attribute-label" data-model="workPackage" data-id="Some subject" data-attribute="Some custom field with spaces"></macro>
        </p>
        <p class="op-uc-p">
          Inline reference to project: <macro class="macro--attribute-label" data-model="project" data-attribute="status"></macro>
        </p>
        <p class="op-uc-p">
          Inline reference to project with id: <macro class="macro--attribute-label" data-model="project" data-id="some id" data-attribute="status"></macro>
        </p>
      EXPECTED
    end

    it 'should match' do
      expect(subject).to be_html_eql(expected)
    end
  end

  describe 'attribute value macros' do
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
         <a class="wiki-anchor icon-paragraph" aria-hidden="true" href="#my-headline"></a>My headline
        </h1>
        <p class="op-uc-p">
          Inline reference to WP by ID: <macro class="macro--attribute-value" data-model="workPackage" data-id="1234" data-attribute="subject"></macro>
        </p>
        <p class="op-uc-p">
          Inline reference to WP by subject: <macro class="macro--attribute-value" data-model="workPackage" data-id="Some subject" data-attribute="Some custom field with spaces"></macro>
        </p>
        <p class="op-uc-p">
          Inline reference to project: <macro class="macro--attribute-value" data-model="project" data-attribute="status"></macro>
        </p>
        <p class="op-uc-p">
          Inline reference to project with id: <macro class="macro--attribute-value" data-model="project" data-id="some id" data-attribute="status"></macro>
        </p>
      EXPECTED
    end

    it 'should match' do
      expect(subject).to be_html_eql(expected)
    end
  end
end
