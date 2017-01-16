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

describe ApplicationHelper, type: :helper do
  include ApplicationHelper
  include WorkPackagesHelper

  describe 'format_activity_description' do
    it 'truncates given text' do
      text = 'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lore'
      expect(format_activity_description(text).size).to eq(120)
    end

    it 'replaces escaped line breaks with html line breaks and should be html_safe' do
      text = "Lorem ipsum dolor sit \namet, consetetur sadipscing elitr, sed diam nonumy eirmod\r tempor invidunt"
      text_html = 'Lorem ipsum dolor sit <br />amet, consetetur sadipscing elitr, sed diam nonumy eirmod<br /> tempor invidunt'
      expect(format_activity_description(text)).to be_html_eql(text_html)
      expect(format_activity_description(text).html_safe?).to be_truthy
    end

    it 'escapes potentially harmful code' do
      text = "Lorem ipsum dolor <script>alert('pwnd');</script> tempor invidunt"
      expect(format_activity_description(text).include?('&lt;script&gt;alert(&#39;pwnd&#39;);&lt;/script&gt;')).to be_truthy
    end
  end

  describe 'footer_content' do
    context 'no additional footer content' do
      before do
        OpenProject::Footer.content = nil
      end

      it { expect(footer_content).to eq(I18n.t(:text_powered_by, link: link_to(OpenProject::Info.app_name, OpenProject::Info.url))) }
    end

    context 'string as additional footer content' do
      before do
        OpenProject::Footer.content = nil
        OpenProject::Footer.add_content('openproject', 'footer')
      end

      it { expect(footer_content.include?(I18n.t(:text_powered_by, link: link_to(OpenProject::Info.app_name, OpenProject::Info.url)))).to be_truthy  }
      it { expect(footer_content.include?("<span class=\"footer_openproject\">footer</span>")).to be_truthy  }
    end

    context 'proc as additional footer content' do
      before do
        OpenProject::Footer.content = nil
        OpenProject::Footer.add_content('openproject', Proc.new { Date.parse(Time.now.to_s) })
      end

      it { expect(footer_content.include?("<span class=\"footer_openproject\">#{Date.parse(Time.now.to_s)}</span>")).to be_truthy  }
    end

    context 'proc which returns nothing' do
      before do
        OpenProject::Footer.content = nil
        OpenProject::Footer.add_content('openproject', Proc.new { 'footer' if false })
      end

      it { expect(footer_content.include?("<span class=\"footer_openproject\">")).to be_falsey }
    end
  end

  describe '.link_to_if_authorized' do
    let(:project) { FactoryGirl.create :valid_project }
    let(:project_member) {
      FactoryGirl.create :user,
                         member_in_project: project,
                         member_through_role: FactoryGirl.create(:role,
                                                                 permissions: [:view_work_packages, :edit_work_packages,
                                                                               :browse_repository, :view_changesets, :view_wiki_pages])
    }
    let(:issue) {
      FactoryGirl.create :work_package,
                         project: project,
                         author: project_member,
                         type: project.types.first
    }

    context 'if user is authorized' do
      before do
        expect(self).to receive(:authorize_for).and_return(true)
        @response = link_to_if_authorized('link_content', {
                                            controller: 'issues',
                                            action: 'show',
                                            id: issue },
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
                                            controller: 'issues',
                                            action: 'show',
                                            id: issue },
                                          class: 'fancy_css_class')
      end

      subject { @response }

      it { is_expected.to be_nil }
    end

    context 'allow using the :controller and :action for the target link' do
      before do
        expect(self).to receive(:authorize_for).and_return(true)
        @response = link_to_if_authorized('By controller/action',
                                          controller: 'issues',
                                          action: 'edit',
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
      it { expect(@links).to be_html_eql("<p class=\"other-formats\">Also available in:<span><a class=\"icon icon-atom\" href=\"/projects.atom\" rel=\"nofollow\">Atom</a></span></p>") }
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
        @project = FactoryGirl.build(:project)
      end

      context 'right now' do
        let(:time) { Time.now }

        it { is_expected.to match /^\<a/ }
        it { is_expected.to match /less than a minute/ }
        it { is_expected.to be_html_safe }
      end

      context 'some time ago' do
        let(:time) {
          Timecop.travel(2.weeks.ago) do
            Time.now
          end
        }

        it { is_expected.to match /^\<a/ }
        it { is_expected.to match /14 days/ }
        it { is_expected.to be_html_safe }
      end
    end

    context 'without project' do
      context 'right now' do
        let(:time) { Time.now }

        it { is_expected.to match /^\<time/ }
        it { is_expected.to match /datetime=\"#{Regexp.escape(time.xmlschema)}\"/ }
        it { is_expected.to match /less than a minute/ }
        it { is_expected.to be_html_safe }
      end

      context 'some time ago' do
        let(:time) {
          Timecop.travel(1.week.ago) do
            Time.now
          end
        }

        it { is_expected.to match /^\<time/ }
        it { is_expected.to match /datetime=\"#{Regexp.escape(time.xmlschema)}\"/ }
        it { is_expected.to match /7 days/ }
        it { is_expected.to be_html_safe }
      end
    end
  end
end
