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

RSpec.describe Notifications::CreateFromModelService::DocumentStrategy do
  it "opts in to mentions via the API requiring the manage_documents permission" do
    expect(described_class.api_mention_permission).to eq(:manage_documents)
  end

  describe ".supports_ian?" do
    it { expect(described_class.supports_ian?(:mentioned)).to be(true) }
    it { expect(described_class.supports_ian?("mentioned")).to be(true) }
    it { expect(described_class.supports_ian?(:subscribed)).to be(false) }
  end

  describe ".supports_mail?" do
    it { expect(described_class.supports_mail?(:mentioned)).to be(true) }
    it { expect(described_class.supports_mail?(:subscribed)).to be(true) }
  end

  describe ".supports_mail_digest?" do
    it { expect(described_class.supports_mail_digest?(:mentioned)).to be(false) }
    it { expect(described_class.supports_mail_digest?(:subscribed)).to be(false) }
  end

  it "keeps subscribed as the only journal based reason" do
    expect(described_class.reasons).to eq(%i[subscribed])
  end
end
