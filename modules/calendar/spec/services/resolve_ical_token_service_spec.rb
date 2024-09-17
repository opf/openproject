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

RSpec.describe Calendar::ResolveICalTokenService, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:query) { create(:query, project:) }

  let(:valid_ical_token_value) { Token::ICal.create_and_return_value(user, query, "My Token") }
  let(:invalid_ical_token_value) { valid_ical_token_value[0..-2] }

  let(:instance) do
    described_class.new
  end

  context "for a given valid ical token value" do
    subject { instance.call(ical_token_string: valid_ical_token_value) }

    it "resolves the ical_token instance as result" do
      ical_token_instance = subject.result

      expect(ical_token_instance)
        .to eql Token::ICal.where(user:).first

      expect(ical_token_instance.user)
        .to eql user

      expect(ical_token_instance.query)
        .to eql query
    end

    it "is a success" do
      expect(subject)
        .to be_success
    end
  end

  context "when given ical token value is invalid" do
    subject { instance.call(ical_token_string: invalid_ical_token_value) }

    it "raises ActiveRecord::RecordNotFound" do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when no ical token value is given" do
    subject { instance.call(ical_token_string: nil) }

    it "raises ActiveRecord::RecordNotFound" do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
