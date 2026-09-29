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
          expect(subject).to redirect_to action: :show, tab: "interface"
        end
      end

      context "when no active token exists" do
        before do
          allow(EnterpriseToken).to receive(:active_tokens).and_return([])
        end

        it "renders show" do
          expect(subject).to redirect_to action: :show, tab: "interface"
        end
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
          expect(response).to have_http_status(:found)
        end
      end

      context "with invalid custom_style input" do
        let(:valid) { false }

        it "renders with error" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template "custom_styles/show"
        end
      end
    end

    describe "#create", with_ee: false do
      let(:custom_style) { CustomStyle.new }
      let(:params) do
        {
          custom_style: { logo: "foo", favicon: "bar", icon_touch: "yay" }
        }
      end

      before do
        post :create, params:
      end

      it "renders a 403" do
        expect(response).to have_http_status(:forbidden)
        expect(flash[:error][:message]).to match /You need the basic enterprise plan to perform this action/
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
            expect(response).to redirect_to(action: :show)
          end
        end

        context "with invalid custom_style input" do
          let(:valid) { false }

          it "renders with error" do
            expect(response).to have_http_status(:unprocessable_entity)
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
            expect(response).to redirect_to(action: :show)
          end
        end

        context "with invalid custom_style input" do
          let(:valid) { false }

          it "renders with error" do
            expect(response).to have_http_status(:unprocessable_entity)
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
          expect(response).to redirect_to(action: :show)
          expect(response).to have_http_status(:see_other)
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

    describe "#logo_mobile_download" do
      before do
        allow(CustomStyle).to receive(:current).and_return(custom_style)
        allow(controller).to receive(:send_file) { controller.head 200 }

        get :logo_mobile_download, params: {
          digest: "1234",
          filename: "logo_mobile_image.png"
        }
      end

      context "when mobile logo is present" do
        let(:custom_style) { build(:custom_style_with_logo_mobile) }

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

      context "when no mobile logo is present" do
        let(:custom_style) { build_stubbed(:custom_style) }

        it "renders with error" do
          expect(controller).not_to have_received(:send_file)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "#logo_mobile_delete", with_ee: %i[define_custom_style] do
      let(:custom_style) { create(:custom_style_with_logo_mobile) }

      context "if it exists" do
        before do
          allow(CustomStyle).to receive(:current).and_return(custom_style)
          allow(custom_style).to receive(:remove_logo_mobile).and_call_original

          delete :logo_mobile_delete
        end

        it "removes the mobile logo from custom_style" do
          expect(response).to redirect_to(action: :show)
          expect(response).to have_http_status(:see_other)
        end
      end

      context "if it does not exist" do
        before do
          allow(CustomStyle).to receive(:current).and_return(nil)
          delete :logo_mobile_delete
        end

        it "renders 404" do
          expect(response).to have_http_status :not_found
        end
      end
    end

    describe "#export_logo_download", with_ee: %i[define_custom_style] do
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
          expect(response).to redirect_to(action: :show)
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

    describe "#export_cover_download", with_ee: %i[define_custom_style] do
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
          expect(response).to redirect_to(action: :show)
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

    describe "#export_footer_download", with_ee: %i[define_custom_style] do
      before do
        allow(CustomStyle).to receive(:current).and_return(custom_style)
        allow(controller).to receive(:send_file) { controller.head 200 }
        get :export_footer_download, params: { digest: "1234", filename: "export_footer_image.png" }
      end

      context "when export cover is present" do
        let(:custom_style) { build(:custom_style_with_export_footer) }

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

    describe "#export_footer_delete", with_ee: %i[define_custom_style] do
      let(:custom_style) { create(:custom_style_with_export_footer) }

      context "if it exists" do
        before do
          allow(CustomStyle).to receive(:current).and_return(custom_style)
          delete :export_footer_delete
        end

        it "removes the export cover from custom_style" do
          expect(response).to redirect_to(action: :show)
        end
      end

      context "if it does not exist" do
        before do
          allow(CustomStyle).to receive(:current).and_return(nil)
          delete :export_footer_delete
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
          expect(response).to redirect_to(action: :show)
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
          expect(response).to redirect_to(action: :show)
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
            expect(response).to redirect_to(action: :show)
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
            expect(response).to redirect_to(action: :show)
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
            expect(response).to redirect_to(action: :show)
          end
        end
      end

      context "if CustomStyle does not exist" do
        before do
          allow(CustomStyle).to receive(:current).and_return(nil)
          post :update_export_cover_text_color, params:
        end

        it "is created" do
          expect(response).to redirect_to(action: :show)
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

      context "when setting a tab to route to" do
        it "redirects to that tab" do
          post :update_colors, params: { tab: :branding, design_colors: [{ "primary-button-color" => "#110000" }] }
          expect(response).to redirect_to(action: :show, tab: :branding)
        end
      end
    end

    describe "#update_themes", with_ee: %i[define_custom_style] do
      let!(:custom_style) { create(:custom_style) }

      before do
        post :update_themes, params: { theme: "OpenProject Gray", tab: :branding }
      end

      it "updates the theme and redirects to the selected tab" do
        expect(custom_style.reload.theme).to eq("OpenProject Gray")
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_update))
        expect(response).to redirect_to(action: :show, tab: :branding)
      end
    end

    describe "update with export font uploads", with_ee: %i[define_custom_style] do
      let(:custom_style) { create(:custom_style) }
      let(:font_file) { Rack::Test::UploadedFile.new(Rails.public_path.join("fonts/noto-emoji/NotoEmoji.ttf"), "font/ttf") }

      before do
        allow(CustomStyle).to receive(:current).and_return(custom_style)
      end

      it "uploads regular font" do
        post :update, params: { custom_style: { export_font_regular: font_file } }
        expect(response).to redirect_to(action: :show)
        expect(custom_style.reload.export_font_regular).to be_present
        expect(File.basename(custom_style.reload.export_font_regular.file.path)).to eq("NotoEmoji.ttf")
      end

      it "uploads bold font" do
        post :update, params: { custom_style: { export_font_bold: font_file } }
        expect(response).to redirect_to(action: :show)
        expect(custom_style.reload.export_font_bold).to be_present
        expect(File.basename(custom_style.reload.export_font_bold.file.path)).to eq("NotoEmoji.ttf")
      end

      it "uploads italic font" do
        post :update, params: { custom_style: { export_font_italic: font_file } }
        expect(response).to redirect_to(action: :show)
        expect(custom_style.reload.export_font_italic).to be_present
        expect(File.basename(custom_style.reload.export_font_italic.file.path)).to eq("NotoEmoji.ttf")
      end

      it "uploads bold italic font" do
        post :update, params: { custom_style: { export_font_bold_italic: font_file } }
        expect(response).to redirect_to(action: :show)
        expect(custom_style.reload.export_font_bold_italic).to be_present
        expect(File.basename(custom_style.reload.export_font_bold_italic.file.path)).to eq("NotoEmoji.ttf")
      end

      describe "update with invalid file", with_ee: %i[define_custom_style] do
        let(:font_file) { Rack::Test::UploadedFile.new(Rails.public_path.join("favicon.ico"), "font/ttf") }

        it "does respect the file size limit" do
          controller.singleton_class.include(CustomStylesControllerHelper)
          allow(controller).to receive(:font_file_size).and_return(40.megabytes)
          post :update, params: { custom_style: { export_font_regular: font_file } }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(custom_style.reload.export_font_regular).not_to be_present
          expect(flash[:error]).to include("is too large")
        end

        it "does not accept a non-font" do
          post :update, params: { custom_style: { export_font_regular: font_file } }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(custom_style.reload.export_font_regular).not_to be_present
          expect(flash[:error]).to include "not a valid TTF font file."
        end
      end
    end

    describe "export font deletions", with_ee: %i[define_custom_style] do
      context "when style exists" do
        it "deletes regular font" do
          style = create(:custom_style_with_export_font_regular)
          allow(CustomStyle).to receive(:current).and_return(style)
          delete :export_font_regular_delete
          expect(response).to redirect_to(action: :show)
          expect(response).to have_http_status(:see_other)
          expect(style.reload.export_font_regular).not_to be_present
        end

        it "deletes bold font" do
          style = create(:custom_style_with_export_font_bold)
          allow(CustomStyle).to receive(:current).and_return(style)
          delete :export_font_bold_delete
          expect(response).to redirect_to(action: :show)
          expect(response).to have_http_status(:see_other)
          expect(style.reload.export_font_bold).not_to be_present
        end

        it "deletes italic font" do
          style = create(:custom_style_with_export_font_italic)
          allow(CustomStyle).to receive(:current).and_return(style)
          delete :export_font_italic_delete
          expect(response).to redirect_to(action: :show)
          expect(response).to have_http_status(:see_other)
          expect(style.reload.export_font_italic).not_to be_present
        end

        it "deletes bold italic font" do
          style = create(:custom_style_with_export_font_bold_italic)
          allow(CustomStyle).to receive(:current).and_return(style)
          delete :export_font_bold_italic_delete
          expect(response).to redirect_to(action: :show)
          expect(response).to have_http_status(:see_other)
          expect(style.reload.export_font_bold_italic).not_to be_present
        end
      end

      context "when no style exists" do
        before do
          allow(CustomStyle).to receive(:current).and_return(nil)
        end

        it "returns 404 for regular" do
          delete :export_font_regular_delete
          expect(response).to have_http_status :not_found
        end

        it "returns 404 for bold" do
          delete :export_font_bold_delete
          expect(response).to have_http_status :not_found
        end

        it "returns 404 for italic" do
          delete :export_font_italic_delete
          expect(response).to have_http_status :not_found
        end

        it "returns 404 for bold italic" do
          delete :export_font_bold_italic_delete
          expect(response).to have_http_status :not_found
        end
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
