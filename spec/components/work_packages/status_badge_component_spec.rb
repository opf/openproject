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

require "rails_helper"

RSpec.describe WorkPackages::StatusBadgeComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:lock) { "[aria-label='#{I18n.t('activerecord.attributes.status.is_readonly')}']" }
  let(:status) { build_stubbed(:status, name: "In progress") }

  subject(:rendered_component) do
    render_component(status:)
  end

  it "renders the status name" do
    expect(rendered_component).to have_primer_label "In progress"
  end

  it "does not lock a status that permits changes" do
    expect(rendered_component).to have_no_css lock
  end

  context "with a read-only status", with_ee: %i[readonly_work_packages] do
    let(:status) { build_stubbed(:status, :readonly, name: "Rejected") }

    it "renders the status name" do
      expect(rendered_component).to have_primer_label "Rejected"
    end

    it "locks the badge, naming what the lock means" do
      expect(rendered_component).to have_css lock
    end

    context "when rendered in the secondary scheme" do
      subject(:rendered_component) do
        render_component(status:, scheme: :secondary)
      end

      it "still locks the badge" do
        expect(rendered_component).to have_css lock
      end
    end
  end

  context "with a read-only status and no Enterprise token" do
    let(:status) { build_stubbed(:status, :readonly, name: "Rejected") }

    it "does not lock the badge, matching what the contract allows" do
      expect(rendered_component).to have_no_css lock
    end
  end
end
