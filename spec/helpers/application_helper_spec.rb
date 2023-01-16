#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

describe ApplicationHelper do
  include ApplicationHelper
  include WorkPackagesHelper

  describe '.link_to_if_authorized' do
    let(:project) { create :valid_project }
    let(:project_member) do
      create :user,
             member_in_project: project,
             member_through_role: create(:role,
                                         permissions: %i[view_work_packages edit_work_packages
                                                         browse_repository view_changesets view_wiki_pages])
    end
    let(:issue) do
      create :work_package,
             project:,
             author: project_member,
             type: project.types.first
    end

    context 'if user is authorized' do
      before do
        expect(self).to receive(:authorize_for).and_return(true)
        @response = link_to_if_authorized('link_content', {
                                            controller: 'work_packages',
                                            action: 'show',
                                            id: issue
                                          },
                                          class: 'fancy_css_class')
      end

      subject { @response }

      it { is_expected.to match /href/ }

      it { is_expected.to match /fancy_css_class/ }
    end

    context 'if user is unauthorized' do
      before do
        expect(self).to receive(:authorize_for).and_return(false)
        @response = link_to_if_authorized('link_content', {
                                            controller: 'work_packages',
                                            action: 'show',
                                            id: issue
                                          },
                                          class: 'fancy_css_class')
      end

      subject { @response }

      it { is_expected.to be_nil }
    end

    context 'allow using the :controller and :action for the target link' do
      before do
        expect(self).to receive(:authorize_for).and_return(true)
        @response = link_to_if_authorized('By controller/action',
                                          controller: 'work_packages',
                                          action: 'show',
                                          id: issue.id)
      end

      subject { @response }

      it { is_expected.to match /href/ }
    end
  end

  describe 'other_formats_links' do
    context 'link given' do
      before do
        @links = other_formats_links { |f| f.link_to 'Atom', url: { controller: :projects, action: :index } }
      end

      it {
        expect(@links).to be_html_eql("<p class=\"other-formats\">Also available in:<span><a class=\"icon icon-atom\" href=\"/projects.atom\" rel=\"nofollow\">Atom</a></span></p>")
      }
    end

    context 'link given but disabled' do
      before do
        allow(Setting).to receive(:feeds_enabled?).and_return(false)
        @links = other_formats_links { |f| f.link_to 'Atom', url: { controller: :projects, action: :index } }
      end

      it { expect(@links).to be_nil }
    end
  end

  describe 'time_tag' do
    around do |example|
      I18n.with_locale(:en) { example.run }
    end

    subject { time_tag(time) }

    context 'with project' do
      before do
        @project = build(:project)
      end

      context 'right now' do
        let(:time) { Time.now }

        it { is_expected.to match /^<a/ }
        it { is_expected.to match /less than a minute/ }
        it { is_expected.to be_html_safe }
      end

      context 'some time ago' do
        let(:time) do
          Timecop.travel(2.weeks.ago) do
            Time.now
          end
        end

        it { is_expected.to match /^<a/ }
        it { is_expected.to match /14 days/ }
        it { is_expected.to be_html_safe }
      end
    end

    context 'without project' do
      context 'right now' do
        let(:time) { Time.now }

        it { is_expected.to match /^<time/ }
        it { is_expected.to match /datetime="#{Regexp.escape(time.xmlschema)}"/ }
        it { is_expected.to match /less than a minute/ }
        it { is_expected.to be_html_safe }
      end

      context 'some time ago' do
        let(:time) do
          Timecop.travel(1.week.ago) do
            Time.now
          end
        end

        it { is_expected.to match /^<time/ }
        it { is_expected.to match /datetime="#{Regexp.escape(time.xmlschema)}"/ }
        it { is_expected.to match /7 days/ }
        it { is_expected.to be_html_safe }
      end
    end
  end
end
