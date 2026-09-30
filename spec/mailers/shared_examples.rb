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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

RSpec.shared_examples_for "mail is sent" do
  let(:letters_sent_count) { 1 }
  let(:mail) { deliveries.first }
  let(:html_body) { mail.body.parts.detect { |p| p.content_type.include? "text/html" }.body.encoded }

  it "actually sends a mail" do
    expect(deliveries.size).to eql(letters_sent_count)
  end

  it "is sent to the recipient" do
    expect(deliveries.first.to).to include(recipient.mail)
  end

  it "is sent from the configured address" do
    expect(deliveries.first.from).to contain_exactly(ApplicationMailer.mail_from)
  end
end

RSpec.shared_examples_for "multiple mails are sent" do |set_letters_sent_count|
  it_behaves_like "mail is sent" do
    let(:letters_sent_count) { set_letters_sent_count }
  end
end

RSpec.shared_examples_for "mail is not sent" do
  it "sends no mail" do
    expect(deliveries).to be_empty
  end
end
