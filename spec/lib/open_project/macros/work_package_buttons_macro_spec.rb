#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'OpenProject work package button macros' do
  include ActionView::Helpers::UrlHelper
  include OpenProject::StaticRouting::UrlHelpers
  include OpenProject::TextFormatting

  def controller
    # no-op
  end

  let(:type) { FactoryGirl.create :type, name: 'MyTaskName' }
  let(:project) { FactoryGirl.create :valid_project, identifier: 'my-project', name: 'My project name', types: [type] }
  let(:user) { FactoryGirl.create :admin }

  let(:input) { }
  subject { format_text(input, project: project) }

  before do
    login_as user
    allow(Setting).to receive(:text_formatting).and_return('textile')
  end

  def error_html(exception_msg)
    "<p><span class=\"flash error macro-unavailable permanent\"> " \
          "Error executing the macro create_work_package_link (#{exception_msg}) </span></p>"
  end

  context 'when nothing passed' do
    let(:input) { '{{create_work_package_link}}' }
    it { is_expected.to be_html_eql("<p><a href=\"/projects/my-project/work_packages/new\">New work package</a></p>") }
  end

  context 'with invalid type' do
    let(:input) { '{{create_work_package_link(InvalidType)}}' }
    it { is_expected.to be_html_eql(error_html("No type found with name 'InvalidType' in project 'My project name'.")) }
  end

  context 'with valid type' do
    let(:input) { '{{create_work_package_link(MyTaskName)}}' }
    it { is_expected.to be_html_eql("<p><a href=\"/projects/my-project/work_packages/new?type=#{type.id}\">New MyTaskName</a></p>") }

    context 'with button style' do
      let(:input) { '{{create_work_package_link(MyTaskName, button)}}' }
      it { is_expected.to be_html_eql("<p><a class=\"button\" href=\"/projects/my-project/work_packages/new?type=#{type.id}\">New MyTaskName</a></p>") }
    end

    context 'without project context' do
      subject { format_text(input, project: nil) }

      it 'does not raise, but print error' do
        expect { subject }.not_to raise_error
        is_expected.to be_html_eql(error_html('Calling create_work_package_link macro from outside project context.'))
      end
    end
  end
end
