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

require "rails_helper"

RSpec.describe Admin::EnterpriseTokens::TableComponent, type: :component do
  include EnterpriseHelper
  include EnterpriseTokenFactory
  include Redmine::I18n

  let(:token) { create_enterprise_token }
  let(:tokens) { [token] }

  subject(:component) { described_class.new(rows: tokens) }

  it "renders multiple tokens in a table with plan and subscriber name in the subscription column" do
    expired_token = create_enterprise_token(subscriber: "My company", expires_at: 1.month.ago)
    active_token = create_enterprise_token(subscriber: "My company", plan: "Premium")
    component = described_class.new(rows: [expired_token, active_token])

    render_inline(component)

    expect(page).to have_text(enterprise_token_plan_name(expired_token), count: 1)
    expect(page).to have_text(enterprise_token_plan_name(active_token), count: 1)
    expect(page).to have_text("My company", count: 2)
  end

  def first_subscription_cell
    page.first(".subscription")
  end

  def subscription_cells
    page.all(".subscription")
  end

  def first_dates_cell
    page.first(".dates")
  end

  def dates_cells
    page.all(".dates")
  end

  context "when a token is a trial" do
    let(:tokens) do
      [
        create_enterprise_token(trial: true),
        create_enterprise_token(trial: true, expires_at: Date.current.prev_day(60))
      ]
    end

    it "displays a 'Trial' accent label in the subscription column" do
      render_inline(component)

      expect(subscription_cells).to all(have_primer_label("Trial", scheme: "accent"))
    end
  end

  context "when a token has invalid domain" do
    let(:token) { create_enterprise_token(domain: "invalid.com") }

    it "displays a 'Invalid domain' danger label in the subscription column" do
      render_inline(component)

      expect(first_subscription_cell).to have_primer_label(count: 1)
      expect(first_subscription_cell).to have_primer_label("Invalid domain", scheme: "danger")
    end
  end

  context "when a token is not active yet" do
    let(:token) { create_enterprise_token(starts_at: Date.current.next_day(30)) }

    it "displays a 'Not active' attention label in the subscription column" do
      render_inline(component)

      expect(first_subscription_cell).to have_primer_label(count: 1)
      expect(first_subscription_cell).to have_primer_label("Not active", scheme: "attention")
    end

    it "has start date in :attention color in the dates column" do
      render_inline(component)

      expect(first_dates_cell).to have_primer_text(format_date(token.starts_at), color: "attention")
                             .and have_primer_text(format_date(token.expires_at), color: "subtle")
    end
  end

  context "when a token is active and nearing expiration date" do
    let(:tokens) do
      [
        create_enterprise_token(expires_at: Date.current),
        create_enterprise_token(expires_at: Date.current.next_day(15))
      ]
    end

    it "displays a 'Expiring soon' attention label in the subscription column" do
      render_inline(component)

      expect(subscription_cells).to all(have_primer_label(count: 1))
      expect(subscription_cells).to all(have_primer_label("Expiring soon", scheme: "attention"))
    end

    it "has expiration date in :attention color in the dates column" do
      render_inline(component)

      expect(dates_cells[0]).to have_primer_text(format_date(tokens.first.starts_at), color: "subtle")
                           .and have_primer_text(format_date(tokens.first.expires_at), color: "attention")
      expect(dates_cells[1]).to have_primer_text(format_date(tokens.second.starts_at), color: "subtle")
                           .and have_primer_text(format_date(tokens.second.expires_at), color: "attention")
    end
  end

  context "when a token reached expiration date but is within the reprieve days" do
    let(:tokens) do
      [
        create_enterprise_token(reprieve_days: 5, expires_at: Date.current.prev_day(1)),
        create_enterprise_token(reprieve_days: 5, expires_at: Date.current.prev_day(5))
      ]
    end

    it "displays a 'In grace period' attention label in the subscription column" do
      render_inline(component)

      expect(subscription_cells).to all(have_primer_label(count: 1))
      expect(subscription_cells).to all(have_primer_label("In grace period", scheme: "attention"))
    end

    it "has expiration date in :attention color in the dates column" do
      render_inline(component)

      expect(dates_cells[0]).to have_primer_text(format_date(tokens.first.starts_at), color: "subtle")
                           .and have_primer_text(format_date(tokens.first.expires_at), color: "attention")
      expect(dates_cells[1]).to have_primer_text(format_date(tokens.second.starts_at), color: "subtle")
                           .and have_primer_text(format_date(tokens.second.expires_at), color: "attention")
    end
  end

  context "when a token is fully expired" do
    let(:tokens) do
      [
        create_enterprise_token(expires_at: Date.current.prev_day(1)),
        create_enterprise_token(expires_at: Date.current.prev_day(5), reprieve_days: 4),
        create_enterprise_token(expires_at: Date.current.prev_day(42), reprieve_days: 30)
      ]
    end

    it "displays a 'Expired' danger label in the subscription column" do
      render_inline(component)

      expect(subscription_cells).to all(have_primer_label(count: 1))
      expect(subscription_cells).to all(have_primer_label("Expired", scheme: "danger"))
    end

    it "has expiration date in :danger color in the dates column" do
      render_inline(component)

      expect(dates_cells[0]).to have_primer_text(format_date(tokens.first.starts_at), color: "subtle")
                           .and have_primer_text(format_date(tokens.first.expires_at), color: "danger")
      expect(dates_cells[1]).to have_primer_text(format_date(tokens.second.starts_at), color: "subtle")
                           .and have_primer_text(format_date(tokens.second.expires_at), color: "danger")
      expect(dates_cells[2]).to have_primer_text(format_date(tokens.third.starts_at), color: "subtle")
                           .and have_primer_text(format_date(tokens.third.expires_at), color: "danger")
    end
  end

  context "when token does not expire" do
    let(:token) do
      create_enterprise_token(expires_at: nil)
    end

    it "displays a 'Unlimited' label in the subscription column" do
      render_inline(component)

      expect(first_dates_cell).to have_primer_text("Unlimited", color: "subtle")
    end
  end
end
