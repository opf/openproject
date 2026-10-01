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

RSpec.describe FormConfigurations::UpdateService, type: :service do
  shared_let(:admin) { create(:admin) }

  let(:form) { create(:form_configuration) }

  def update(model, **params) = described_class.new(user: admin, model:).call(**params)

  before { login_as(admin) }

  it "marks a form as default, taking the mark from the previous one" do
    previous = create(:form_configuration, is_default: true)

    expect(update(form, is_default: true)).to be_success
    expect(form.reload).to be_is_default
    expect(previous.reload).not_to be_is_default
  end

  it "refuses to remove the mark from the default form" do
    default = create(:form_configuration, is_default: true)

    result = update(default, is_default: false)

    expect(result).to be_failure
    expect(result.errors).to be_of_kind(:is_default, :unremovable)
    expect(default.reload).to be_is_default
  end

  it "refuses someone who is not an administrator" do
    result = described_class.new(user: create(:user), model: form).call(is_default: true)

    expect(result).to be_failure
    expect(form.reload).not_to be_is_default
  end
end
