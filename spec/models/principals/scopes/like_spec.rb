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

RSpec.describe Principals::Scopes::Like do
  describe ".like" do
    let!(:login) do
      create(:principal, login: "login")
    end
    let!(:login2) do
      create(:principal, login: "login2")
    end
    let!(:firstname) do
      create(:principal, firstname: "firstname")
    end
    let!(:firstname2) do
      create(:principal, firstname: "firstname2")
    end
    let!(:lastname) do
      create(:principal, lastname: "lastname")
    end
    let!(:lastname2) do
      create(:principal, lastname: "lastname2")
    end
    let!(:mail) do
      create(:principal, mail: "mail@example.com")
    end
    let!(:mail2) do
      create(:principal, mail: "mail2@example.com")
    end

    it "finds by login" do
      expect(Principal.like("login"))
        .to contain_exactly(login, login2)
    end

    it "finds by firstname" do
      expect(Principal.like("firstname"))
        .to contain_exactly(firstname, firstname2)
    end

    it "finds by lastname" do
      expect(Principal.like("lastname"))
        .to contain_exactly(lastname, lastname2)
    end

    it "finds by mail" do
      expect(Principal.like("mail"))
        .to contain_exactly(mail, mail2)
    end
  end
end
