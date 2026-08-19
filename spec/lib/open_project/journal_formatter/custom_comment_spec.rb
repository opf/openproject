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

RSpec.describe OpenProject::JournalFormatter::CustomComment do
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  let(:instance) { described_class.new(journal) }
  let(:id) { 1 }
  let(:journal) { instance_double(Journal, id:) }
  let(:key) { "custom_comment_#{custom_field.id}" }
  let(:options) { {} }
  let(:custom_field) { build_stubbed(:project_custom_field) }

  let(:path) { diff_journal_path(id: journal.id, field: key.downcase) }
  let(:url) do
    diff_journal_url(id: journal.id, field: key.downcase, protocol: Setting.protocol, host: Setting.host_name)
  end
  let(:relative_link) { link_to(I18n.t(:label_details), path, class: "diff-details", target: "_top") }
  let(:full_link) { link_to(I18n.t(:label_details), url, class: "diff-details", target: "_top") }

  let(:expected) do
    I18n.t(expected_i18n_key, label: expected_label, link: expected_link)
  end

  subject(:rendered) { instance.render(key, values, **options) }

  before do
    allow(CustomField).to receive(:find_by).and_return(nil)
    allow(CustomField)
      .to receive(:find_by)
      .with(id: custom_field.id)
      .and_return(custom_field)
  end

  shared_examples "results are expected" do
    describe "with the first value being nil, and the second a string" do
      let(:values) { [nil, "new value"] }
      let(:expected_i18n_key) { :text_journal_set_with_diff }

      it { expect(rendered).to be_html_eql(expected) }
    end

    describe "with both values being strings" do
      let(:values) { ["old value", "new value"] }
      let(:expected_i18n_key) { :text_journal_changed_with_diff }

      it { expect(rendered).to be_html_eql(expected) }
    end

    describe "with the first value being a string, and the second nil" do
      let(:values) { ["old_value", nil] }
      let(:expected_i18n_key) { :text_journal_deleted_with_diff }

      it { expect(rendered).to be_html_eql(expected) }
    end
  end

  context "with html requested by default" do
    let(:expected_label) { "<strong>#{custom_field.name} comment</strong>" }
    let(:expected_link) { relative_link }

    include_examples "results are expected"
  end

  context "with the custom field being deleted" do
    let(:key) { "custom_fields_#{custom_field.id + 1}" }
    let(:expected_label) { "<strong>#{I18n.t(:label_deleted_custom_field)} comment</strong>" }
    let(:expected_link) { relative_link }

    include_examples "results are expected"
  end

  context "with non html requested" do
    let(:options) { { html: false } }
    let(:expected_label) { "#{custom_field.name} comment" }
    let(:expected_link) { path }

    include_examples "results are expected"
  end

  context "with full url requested" do
    let(:options) { { only_path: false } }
    let(:expected_label) { "<strong>#{custom_field.name} comment</strong>" }
    let(:expected_link) { full_link }

    include_examples "results are expected"
  end
end
