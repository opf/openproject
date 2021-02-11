#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require_relative './expected_markdown'

describe OpenProject::TextFormatting,
         'work package button macro' do
  include_context 'expected markdown modules'
  shared_let(:admin) { FactoryBot.create :admin }

  let(:type) { FactoryBot.create :type, name: 'MyTaskName' }
  let(:project) { FactoryBot.create :valid_project, identifier: 'my-project', name: 'My project name', types: [type] }

  before do
    login_as admin
  end

  def error_html(exception_msg)
    "<p class=\"op-uc-p\"><macro class=\"macro-unavailable\" data-macro-name=\"create_work_package_link\"> " \
          "Error executing the macro create_work_package_link (#{exception_msg}) </span></p>"
  end

  let(:options) { { project: project } }

  context 'old macro syntax no longer works' do
    it_behaves_like 'format_text produces' do
      let(:raw) do
        <<~RAW
          {{create_work_package_link}}
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">#{raw}</p>
        EXPECTED
      end
    end
  end

  context 'when nothing passed' do
    it_behaves_like 'format_text produces' do
      let(:raw) do
        <<~RAW
          <macro class="create_work_package_link"></macro>
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">
            <a class="op-uc-link" href="/projects/my-project/work_packages/new">New work package</a>
          </p>
        EXPECTED
      end
    end
  end

  context 'with invalid type' do
    it_behaves_like 'format_text produces' do
      let(:raw) do
        <<~RAW
          <macro class="create_work_package_link" data-type="InvalidType"></macro>
        RAW
      end

      let(:expected) do
        error_html("No type found with name 'InvalidType' in project 'My project name'.")
      end
    end
  end

  context 'with valid type' do
    it_behaves_like 'format_text produces' do
      let(:raw) do
        <<~RAW
          <macro class="create_work_package_link" data-type="MyTaskName"></macro>
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">
            <a class="op-uc-link" href="/projects/my-project/work_packages/new?type=#{type.id}">New MyTaskName</a>
          </p>
        EXPECTED
      end
    end

    context 'with button style' do
      it_behaves_like 'format_text produces' do
        let(:raw) do
          <<~RAW
            <macro class="create_work_package_link" data-type="MyTaskName" data-classes="button"></macro>
          RAW
        end

        let(:expected) do
          <<~EXPECTED
            <p class="op-uc-p">
              <a class="button op-uc-link" href="/projects/my-project/work_packages/new?type=#{type.id}">New MyTaskName</a>
            </p>
          EXPECTED
        end
      end
    end

    context 'without project context' do
      let(:options) { { project: nil } }

      it_behaves_like 'format_text produces' do
        let(:raw) do
          <<~RAW
            <macro class="create_work_package_link" data-type="MyTaskName"></macro>
          RAW
        end

        let(:expected) do
          error_html('Calling create_work_package_link macro from outside project context.')
        end
      end
    end
  end
end
