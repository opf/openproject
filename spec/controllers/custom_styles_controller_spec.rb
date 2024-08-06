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

RSpec.describe CustomStylesController do
  before do
    login_as user
  end

  context "with admin" do
    let(:user) { build(:admin) }

    describe "#show" do
      subject { get :show }

      context "when active token exists", with_ee: %i[define_custom_style] do
        it "renders show" do
          expect(subject).to be_successful
          expect(response).to render_template "show"
        end
      end

      context "when no active token exists" do
        before do
          allow(EnterpriseToken).to receive(:current).and_return(nil)
        end

        it "redirects to #upsale" do
          expect(subject).to redirect_to action: :upsale
        end
      end
    end

    describe "#upsale" do
      subject { get :upsale }

      it "renders upsale" do
        expect(subject).to be_successful
        expect(subject).to render_template "upsale"
      end
    end

    describe "#create", with_ee: %i[define_custom_style] do
      let(:custom_style) { CustomStyle.new }
      let(:params) do
        {
          custom_style: { logo: "foo", favicon: "bar", icon_touch: "yay" }
        }
      end

      before do
        allow(CustomStyle).to receive(:create).and_return(custom_style)
        allow(custom_style).to receive(:valid?).and_return(valid)

        post :create, params:
      end

      context "with valid custom_style input" do
        let(:valid) { true }

        it "redirects to show" do
          expect(response).to redirect_to action: :show
        end
      end

      context "with invalid custom_style input" do
        let(:valid) { false }

        it "renders with error" do
          expect(response).not_to be_redirect
          expect(response).to render_template "custom_styles/show"
        end
      end
    end

    describe "#update", with_ee: %i[define_custom_style] do
      let(:custom_style) { build(:custom_style_with_logo) }
      let(:params) do
        {
          custom_style: { logo: "foo", favicon: "bar", icon_touch: "yay" }
        }
      end

      context "with an existing CustomStyle" do
        before do
          allow(CustomStyle).to receive(:current).and_return(custom_style)
          allow(custom_style).to receive(:update).and_return(valid)

          post :update, params:
        end

        context "with valid custom_style input" do
          let(:valid) { true }

          it "redirects to show" do
            expect(response).to redirect_to action: :show
          end
        end

        context "with invalid custom_style input" do
          let(:valid) { false }

          it "renders with error" do
            expect(response).not_to be_redirect
            expect(response).to render_template "custom_styles/show"
          end
        end
      end

      context "without an existing CustomStyle" do
        before do
          allow(CustomStyle).to receive(:create!).and_return(custom_style)
          allow(custom_style).to receive(:update).and_return(valid)

          post :update, params:
        end

        context "with valid custom_style input" do
          let(:valid) { true }

          it "redirects to show" do
            expect(response).to redirect_to action: :show
          end
        end

        context "with invalid custom_style input" do
          let(:valid) { false }

          it "renders with error" do
            expect(response).not_to be_redirect
            expect(response).to render_template "custom_styles/show"
          end
        end
      end
    end

    describe "#logo_download" do
      before do
        allow(CustomStyle).to receive(:current).and_return(custom_style)
        allow(controller).to receive(:send_file) { controller.head 200 }
        get :logo_download, params: { digest: "1234", filename: "logo_image.png" }
      end

      context "when logo is present" do
        let(:custom_style) { build(:custom_style_with_logo) }

        it "sends a file" do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when no custom style is present" do
        let(:custom_style) { nil }

        it "renders with error" do
          expect(controller).not_to have_received(:send_file)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when no logo is present" do
        let(:custom_style) { build_stubbed(:custom_style) }

        it "renders with error" do
          expect(controller).not_to have_received(:send_file)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "#logo_delete", with_ee: %i[define_custom_style] do
      let(:custom_style) { create(:custom_style_with_logo) }

      context "if it exists" do
        before do
          allow(CustomStyle).to receive(:current).and_return(custom_style)
          allow(custom_style).to receive(:remove_logo).and_call_original
          delete :logo_delete
        end

        it "removes the logo from custom_style" do
          expect(response).to redirect_to action: :show
        end
      end

      context "if it does not exist" do
        before do
          allow(CustomStyle).to receive(:current).and_return(nil)
          delete :logo_delete
        end

        it "renders 404" do
          expect(response).to have_http_status :not_found
        end
      end
    end

    describe "#export_logo_download" do
      before do
        allow(CustomStyle).to receive(:current).and_return(custom_style)
        allow(controller).to receive(:send_file) { controller.head 200 }
        get :export_logo_download, params: { digest: "1234", filename: "export_logo_image.png" }
      end

      context "when export logo is present" do
        let(:custom_style) { build(:custom_style_with_export_logo) }

        it "sends a file" do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when no custom style is present" do
        let(:custom_style) { nil }

        it "renders with error" do
          expect(controller).not_to have_received(:send_file)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when no export logo is present" do
        let(:custom_style) { build_stubbed(:custom_style) }

        it "renders with error" do
          expect(controller).not_to have_received(:send_file)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "#export_logo_delete", with_ee: %i[define_custom_style] do
      let(:custom_style) { create(:custom_style_with_export_logo) }

      context "if it exists" do
        before do
          allow(CustomStyle).to receive(:current).and_return(custom_style)
          allow(custom_style).to receive(:remove_export_logo).and_call_original
          delete :export_logo_delete
        end

        it "removes the export logo from custom_style" do
          expect(response).to redirect_to action: :show
        end
      end

      context "if it does not exist" do
        before do
          allow(CustomStyle).to receive(:current).and_return(nil)
          delete :export_logo_delete
        end

        it "renders 404" do
          expect(response).to have_http_status :not_found
        end
      end
    end

    describe "#export_cover_download" do
      before do
        allow(CustomStyle).to receive(:current).and_return(custom_style)
        allow(controller).to receive(:send_file) { controller.head 200 }
        get :export_cover_download, params: { digest: "1234", filename: "export_cover_image.png" }
      end

      context "when export cover is present" do
        let(:custom_style) { build(:custom_style_with_export_cover) }

        it "sends a file" do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when no custom style is present" do
        let(:custom_style) { nil }

        it "renders with error" do
          expect(controller).not_to have_received(:send_file)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when no export cover is present" do
        let(:custom_style) { build_stubbed(:custom_style) }

        it "renders with error" do
          expect(controller).not_to have_received(:send_file)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "#export_cover_delete", with_ee: %i[define_custom_style] do
      let(:custom_style) { create(:custom_style_with_export_cover) }

      context "if it exists" do
        before do
          allow(CustomStyle).to receive(:current).and_return(custom_style)
          delete :export_cover_delete
        end

        it "removes the export cover from custom_style" do
          expect(response).to redirect_to action: :show
        end
      end

      context "if it does not exist" do
        before do
          allow(CustomStyle).to receive(:current).and_return(nil)
          delete :export_cover_delete
        end

        it "renders 404" do
          expect(response).to have_http_status :not_found
        end
      end
    end

    describe "#favicon_download" do
      before do
        allow(CustomStyle).to receive(:current).and_return(custom_style)
        allow(controller).to receive(:send_file) { controller.head 200 }
        get :favicon_download, params: { digest: "1234", filename: "favicon_image.png" }
      end

      context "when favicon is present" do
        let(:custom_style) { build(:custom_style_with_favicon) }

        it "sends a file" do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when no custom style is present" do
        let(:custom_style) { nil }

        it "renders with error" do
          expect(controller).not_to have_received(:send_file)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when no favicon is present" do
        let(:custom_style) { build(:custom_style) }

        it "renders with error" do
          expect(controller).not_to have_received(:send_file)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "#favicon_delete", with_ee: %i[define_custom_style] do
      let(:custom_style) { create(:custom_style_with_favicon) }

      context "if it exists" do
        before do
          allow(CustomStyle).to receive(:current).and_return(custom_style)
          allow(custom_style).to receive(:remove_favicon).and_call_original
          delete :favicon_delete
        end

        it "removes the favicon from custom_style" do
          expect(response).to redirect_to action: :show
        end
      end

      context "if it does not exist" do
        before do
          allow(CustomStyle).to receive(:current).and_return(nil)
          delete :favicon_delete
        end

        it "renders 404" do
          expect(response).to have_http_status :not_found
        end
      end
    end

    describe "#touch_icon_download" do
      before do
        allow(CustomStyle).to receive(:current).and_return(custom_style)
        allow(controller).to receive(:send_file) { controller.head 200 }
        get :touch_icon_download, params: { digest: "1234", filename: "touch_icon_image.png" }
      end

      context "when touch icon is present" do
        let(:custom_style) { build(:custom_style_with_touch_icon) }

        it "sends a file" do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when no custom style is present" do
        let(:custom_style) { nil }

        it "renders with error" do
          expect(controller).not_to have_received(:send_file)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when no touch icon is present" do
        let(:custom_style) { build(:custom_style) }

        it "renders with error" do
          expect(controller).not_to have_received(:send_file)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "#touch_icon_delete", with_ee: %i[define_custom_style] do
      let(:custom_style) { create(:custom_style_with_touch_icon) }

      context "if it exists" do
        before do
          allow(CustomStyle).to receive(:current).and_return(custom_style)
          allow(custom_style).to receive(:remove_touch_icon).and_call_original
          delete :touch_icon_delete
        end

        it "removes the touch icon from custom_style" do
          expect(response).to redirect_to action: :show
        end
      end

      context "if it does not exist" do
        before do
          allow(CustomStyle).to receive(:current).and_return(nil)
          delete :touch_icon_delete
        end

        it "renders 404" do
          expect(response).to have_http_status :not_found
        end
      end
    end

    describe "#update_export_cover_text_color", with_ee: %i[define_custom_style] do
      let(:params) do
        { export_cover_text_color: "#990000" }
      end

      context "if CustomStyle exists" do
        let(:custom_style) { CustomStyle.new }

        before do
          allow(CustomStyle).to receive(:current).and_return(custom_style)
          allow(custom_style).to receive(:export_cover_text_color).and_call_original
        end

        context "with valid parameter" do
          before do
            post :update_export_cover_text_color, params:
          end

          it "saves the color" do
            expect(custom_style.export_cover_text_color).to eq("#990000")
            expect(response).to redirect_to action: :show
          end
        end

        context "with valid empty parameter" do
          let(:params) do
            { export_cover_text_color: "" }
          end

          before do
            custom_style.export_cover_text_color = "#990000"
            custom_style.save
            post :update_export_cover_text_color, params:
          end

          it "removes the color" do
            expect(custom_style.export_cover_text_color).to be_nil
            expect(response).to redirect_to action: :show
          end
        end

        context "with invalid parameter" do
          let(:params) do
            { export_cover_text_color: "red" } # we only accept hexcodes
          end

          before do
            post :update_export_cover_text_color, params:
          end

          it "ignores the parameter" do
            expect(custom_style.export_cover_text_color).to be_nil
            expect(response).to redirect_to action: :show
          end
        end
      end

      context "if CustomStyle does not exist" do
        before do
          allow(CustomStyle).to receive(:current).and_return(nil)
          post :update_export_cover_text_color, params:
        end

        it "is created" do
          expect(response).to redirect_to action: :show
        end
      end
    end

    describe "#update_colors", with_ee: %i[define_custom_style] do
      let(:params) do
        {
          design_colors: [{ "primary-button-color" => "#990000" }]
        }
      end

      before do
        post :update_colors, params:
      end

      it "saves DesignColor instances" do
        design_colors = DesignColor.all
        expect(design_colors.size).to eq(1)
        expect(design_colors.first.hexcode).to eq("#990000")
        expect(response).to redirect_to action: :show
      end

      it "updates DesignColor instances" do
        post :update_colors, params: { design_colors: [{ "primary-button-color" => "#110000" }] }
        design_colors = DesignColor.all
        expect(design_colors.size).to eq(1)
        expect(design_colors.first.hexcode).to eq("#110000")
        expect(response).to redirect_to action: :show
      end

      it "deletes DesignColor instances for each param" do
        expect(DesignColor.count).to eq(1)
        post :update_colors, params: { design_colors: [{ "primary-button-color" => "" }] }
        expect(DesignColor.count).to eq(0)
        expect(response).to redirect_to action: :show
      end
    end
  end

  context "for a regular user" do
    let(:user) { build(:user) }

    describe "#get" do
      before do
        get :show
      end

      it "requires admin" do
        expect(response).to have_http_status :forbidden
      end
    end
  end

  context "for an anonymous user" do
    let(:user) { User.anonymous }

    describe "#logo_download" do
      before do
        allow(CustomStyle).to receive(:current).and_return(custom_style)
        allow(controller).to receive(:send_file) { controller.head 200 }
        get :logo_download, params: { digest: "1234", filename: "logo_image.png" }
      end

      context "when logo is present" do
        let(:custom_style) { build(:custom_style_with_logo) }

        it "sends a file" do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when no logo is present" do
        let(:custom_style) { nil }

        it "renders with error" do
          expect(controller).not_to have_received(:send_file)
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
