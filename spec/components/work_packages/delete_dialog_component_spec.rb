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

RSpec.describe WorkPackages::DeleteDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:home_project) { create(:project, name: "Home project") }
  shared_let(:deletable_project) { create(:project, name: "Deletable project") }

  let(:home_permissions) { %i[view_work_packages delete_work_packages] }
  let(:user) do
    create(:user,
           member_with_permissions: {
             home_project => home_permissions,
             deletable_project => %i[view_work_packages delete_work_packages]
           })
  end

  shared_let(:work_package) { create(:work_package, project: home_project, subject: "Parent to delete") }

  subject do
    render_inline(described_class.new(work_package:))
    page
  end

  before do
    login_as(user)
  end

  def t(key, **)
    I18n.t("work_packages.delete_dialog.#{key}", **)
  end

  def deletable_child
    create(:work_package, project: deletable_project, parent: work_package, subject: "Deletable child")
  end

  context "with no descendants" do
    it "asks about the work package alone and mentions no descendants" do
      expect(subject).to have_text t("description", name: work_package.to_s)
      expect(subject).to have_text t("confirm_deletion")
      expect(subject).to have_no_text "descendant"
    end
  end

  context "with descendants" do
    before { deletable_child }

    it "asks whether to delete the descendants too" do
      expect(subject).to have_text t("descendants_choice.question")
    end

    it "offers both choices, defaulting to deleting the descendants" do
      expect(subject).to have_text t("descendants_choice.self_only_label")
      expect(subject).to have_checked_field(t("descendants_choice.with_descendants_label"), visible: :all)
    end

    it "does not preview the descendants or ask to confirm them yet" do
      expect(subject).to have_no_text "Deletable child"
      expect(subject).to have_no_text t("confirm_descendants_deletion")
      expect(subject).to have_no_text t("confirm_deletion")
    end
  end
end
