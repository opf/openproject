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
require_relative "ifc_upload_shared_examples"

RSpec.describe "direct IFC upload", :js, with_config: { edition: "bim" }, with_direct_uploads: :redirect do
  it_behaves_like "can upload an IFC file" do
    # with direct upload, we don't get the model name
    let(:model_name) { "model.ifc" }

    context "when the file size exceeds the allowed maximum", with_settings: { attachment_max_size: 1 } do
      it "invalidates the form via JavaScript preventing submission" do
        pending "This test is currently flaky due to an unknown reason"

        visit new_bcf_project_ifc_model_path(project_id: project.identifier)

        page.attach_file("file", ifc_fixture.path, visible: :all)

        form_validity = page.evaluate_script <<~JS
          document
            .querySelector('#new_bim_ifc_models_ifc_model')
            .checkValidity();
        JS

        expect(form_validity).to be(false)
      end
    end
  end
end
