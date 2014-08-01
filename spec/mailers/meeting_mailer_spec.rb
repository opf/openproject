#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe MeetingMailer do
  let(:role) { FactoryGirl.create(:role, permissions: [:view_meetings]) }
  let(:project) { FactoryGirl.create(:project) }
  let(:author) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:watcher1) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:watcher2) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:meeting) { FactoryGirl.create(:meeting, author: author, project: project) }
  let(:meeting_agenda) do
    FactoryGirl.create(:meeting_agenda, meeting: meeting)
  end

  before(:each) do
    author.pref[:no_self_notified] = true
    author.save!
    meeting.participants.merge([meeting.participants.build(user: watcher1, invited: true, attended: false),
                                meeting.participants.build(user: watcher1, invited: true, attended: false)])
    meeting.save!
  end

  describe "content_for_review" do
    let(:mail) { MeetingMailer.content_for_review meeting_agenda, 'agenda', author.mail}
    # this is needed to call module functions from Redmine::I18n
    let(:i18n) do
      class A
        include Redmine::I18n
        public :format_date, :format_time
      end
      A.new
    end

    it "renders the headers" do
      mail.subject.should include(meeting.project.name)
      mail.subject.should include(meeting.title)
      mail.from.should eq([Setting.mail_from])
      mail.to.should eq([author.mail])
    end

    it "renders the text body" do
      check_meeting_mail_content mail.text_part.body
    end

    it "renders the html body" do
      check_meeting_mail_content mail.html_part.body
    end
  end

  def check_meeting_mail_content(body)
    body.should include(meeting.project.name)
    body.should include(meeting.title)
    body.should include(i18n.format_date meeting.start_date)
    body.should include(i18n.format_time meeting.start_time, false)
    body.should include(i18n.format_time meeting.end_time, false)
    body.should include(meeting.participants[0].name)
    body.should include(meeting.participants[1].name)
  end

  def save_and_open_mail_html_body(mail)
    save_and_open_mail_part mail.html_part.body
  end

  def save_and_open_mail_text_body(mail)
    save_and_open_mail_part mail.text_part.body
  end

  def save_and_open_mail_part(part)
    FileUtils.mkdir_p(Rails.root.join('tmp/mails'))

    page_path = Rails.root.join("tmp/mails/#{SecureRandom.hex(16)}.html").to_s
    File.open(page_path, 'w') { |f| f.write(part) }

    Launchy.open(page_path)

    begin
      binding.pry
    rescue NoMethodError
      debugger
    end

    FileUtils.rm(page_path)
  end
end
