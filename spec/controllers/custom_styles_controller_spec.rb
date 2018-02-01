#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe CustomStylesController, type: :controller do
  before do
    login_as user
  end

  context 'with admin' do
    let(:user) { FactoryGirl.build(:admin) }

    describe '#show' do
      subject { get :show }
      render_views

      context 'when active token exists' do
        before do
          allow(EnterpriseToken).to receive(:allows_to?).and_return(false)
          allow(EnterpriseToken).to receive(:allows_to?).with(:define_custom_style).and_return(true)
        end

        it 'renders show' do
          expect(subject).to be_success
          expect(response).to render_template 'show'
        end
      end

      context 'when no active token exists' do
        before do
          allow(EnterpriseToken).to receive(:current).and_return(nil)
        end

        it 'redirects to #upsale' do
          expect(subject).to redirect_to action: :upsale
        end
      end
    end

    describe "#upsale" do
      subject { get :upsale }
      render_views

      it 'renders upsale' do
        expect(subject).to be_success
        expect(subject).to render_template 'upsale'
      end
    end

    describe "#create" do
      let(:custom_style) { CustomStyle.new }
      let(:params) do
        {
          custom_style: { logo: 'foo', favicon: 'bar', icon_touch: 'yay' }
        }
      end

      before do
        allow(EnterpriseToken).to receive(:allows_to?).and_return(false)
        allow(EnterpriseToken).to receive(:allows_to?).with(:define_custom_style).and_return(true)

        expect(CustomStyle).to receive(:create).and_return(custom_style)
        expect(custom_style).to receive(:valid?).and_return(valid)

        post :create, params: params
      end

      context 'valid custom_style input' do
        let(:valid) { true }

        it 'redirects to show' do
          expect(response).to redirect_to action: :show
        end
      end

      context 'invalid custom_style input' do
        let(:valid) { false }

        it 'renders with error' do
          expect(response).not_to be_redirect
          expect(response).to render_template 'custom_styles/show'
        end
      end
    end

    describe "#update" do
      let(:custom_style) { FactoryGirl.build(:custom_style_with_logo) }
      let(:params) do
        {
          custom_style: { logo: 'foo', favicon: 'bar', icon_touch: 'yay' }
        }
      end

      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(:define_custom_style).and_return(true)

        expect(CustomStyle).to receive(:current).and_return(custom_style)
        expect(custom_style).to receive(:update_attributes).and_return(valid)

        post :update, params: params
      end

      context 'valid custom_style input' do
        let(:valid) { true }

        it 'redirects to show' do
          expect(response).to redirect_to action: :show
        end
      end

      context 'invalid custom_style input' do
        let(:valid) { false }

        it 'renders with error' do
          expect(response).not_to be_redirect
          expect(response).to render_template 'custom_styles/show'
        end
      end
    end

    describe "#logo_download" do
      render_views

      before do
        expect(CustomStyle).to receive(:current).and_return(custom_style)
        allow(controller).to receive(:send_file) { controller.head 200 }
        get :logo_download, params: { digest: "1234", filename: "logo_image.png" }
      end

      context "when logo is present" do
        let(:custom_style) { FactoryGirl.build(:custom_style_with_logo) }

        it 'will send a file' do
          expect(response.status).to eq(200)
        end
      end

      context "when no custom style is present" do
        let(:custom_style) { nil }

        it 'renders with error' do
          expect(controller).to_not receive(:send_file)
          expect(response.status).to eq(404)
        end
      end

      context "when no logo is present" do
        let(:custom_style) { FactoryGirl.build_stubbed(:custom_style) }

        it 'renders with error' do
          expect(controller).to_not receive(:send_file)
          expect(response.status).to eq(404)
        end
      end
    end

    describe "#logo_delete" do
      let(:custom_style) { FactoryGirl.build(:custom_style_with_logo) }

      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(:define_custom_style).and_return(true)
      end

      context 'if it exists' do
        before do
          expect(CustomStyle).to receive(:current).and_return(custom_style)
          expect(custom_style).to receive(:remove_logo!).and_return(custom_style)
          delete :logo_delete
        end

        it 'removes the logo from custom_style' do
          expect(response).to redirect_to action: :show
        end
      end

      context 'if it does not exist' do
        before do
          expect(CustomStyle).to receive(:current).and_return(nil)
          delete :logo_delete
        end

        it 'renders 404' do
          expect(response.status).to eq 404
        end
      end
    end

    describe "#favicon_download" do
      render_views

      before do
        expect(CustomStyle).to receive(:current).and_return(custom_style)
        allow(controller).to receive(:send_file) { controller.head 200 }
        get :favicon_download, params: { digest: "1234", filename: "favicon_image.png" }
      end

      context "when favicon is present" do
        let(:custom_style) { FactoryGirl.build(:custom_style_with_favicon) }

        it 'will send a file' do
          expect(response.status).to eq(200)
        end
      end

      context "when no custom style is present" do
        let(:custom_style) { nil }

        it 'renders with error' do
          expect(controller).to_not receive(:send_file)
          expect(response.status).to eq(404)
        end
      end

      context "when no favicon is present" do
        let(:custom_style) { FactoryGirl.build(:custom_style) }

        it 'renders with error' do
          expect(controller).to_not receive(:send_file)
          expect(response.status).to eq(404)
        end
      end
    end

    describe "#favicon_delete" do
      let(:custom_style) { FactoryGirl.build(:custom_style_with_favicon) }

      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(:define_custom_style).and_return(true)
      end

      context 'if it exists' do
        before do
          expect(CustomStyle).to receive(:current).and_return(custom_style)
          expect(custom_style).to receive(:remove_favicon!).and_return(custom_style)
          delete :favicon_delete
        end

        it 'removes the favicon from custom_style' do
          expect(response).to redirect_to action: :show
        end
      end

      context 'if it does not exist' do
        before do
          expect(CustomStyle).to receive(:current).and_return(nil)
          delete :favicon_delete
        end

        it 'renders 404' do
          expect(response.status).to eq 404
        end
      end
    end

    describe "#touch_icon_download" do
      render_views

      before do
        expect(CustomStyle).to receive(:current).and_return(custom_style)
        allow(controller).to receive(:send_file) { controller.head 200 }
        get :touch_icon_download, params: { digest: "1234", filename: "touch_icon_image.png" }
      end

      context "when touch icon is present" do
        let(:custom_style) { FactoryGirl.build(:custom_style_with_touch_icon) }

        it 'will send a file' do
          expect(response.status).to eq(200)
        end
      end

      context "when no custom style is present" do
        let(:custom_style) { nil }

        it 'renders with error' do
          expect(controller).to_not receive(:send_file)
          expect(response.status).to eq(404)
        end
      end

      context "when no touch icon is present" do
        let(:custom_style) { FactoryGirl.build(:custom_style) }

        it 'renders with error' do
          expect(controller).to_not receive(:send_file)
          expect(response.status).to eq(404)
        end
      end
    end

    describe "#touch_icon_delete" do
      let(:custom_style) { FactoryGirl.build(:custom_style_with_touch_icon) }

      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(:define_custom_style).and_return(true)
      end

      context 'if it exists' do
        before do
          expect(CustomStyle).to receive(:current).and_return(custom_style)
          expect(custom_style).to receive(:remove_touch_icon!).and_return(custom_style)
          delete :touch_icon_delete
        end

        it 'removes the touch icon from custom_style' do
          expect(response).to redirect_to action: :show
        end
      end

      context 'if it does not exist' do
        before do
          expect(CustomStyle).to receive(:current).and_return(nil)
          delete :touch_icon_delete
        end

        it 'renders 404' do
          expect(response.status).to eq 404
        end
      end
    end

    describe "#update_colors" do
      let(:params) do
        {
          design_colors: [{ "primary-color" => "#990000" }]
        }
      end

      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(:define_custom_style).and_return(true)

        post :update_colors, params: params
      end

      it "saves DesignColor instances" do
        design_colors = DesignColor.all
        expect(design_colors.size).to eq(1)
        expect(design_colors.first.hexcode).to eq("#990000")
        expect(response).to redirect_to action: :show
      end

      it "updates DesignColor instances" do
        post :update_colors, params: { design_colors: [{ "primary-color" => "#110000" }] }
        design_colors = DesignColor.all
        expect(design_colors.size).to eq(1)
        expect(design_colors.first.hexcode).to eq("#110000")
        expect(response).to redirect_to action: :show
      end

      it "deletes DesignColor instances for each param" do
        expect(DesignColor.count).to eq(1)
        post :update_colors, params: { design_colors: [{ "primary-color" => "" }] }
        expect(DesignColor.count).to eq(0)
        expect(response).to redirect_to action: :show
      end
    end
  end

  context 'regular user' do
    let(:user) { FactoryGirl.build(:user) }

    describe '#get' do
      before do
        get :show
      end

      it 'requires admin' do
        expect(response.status).to eq 403
      end
    end
  end

  context 'anonymous user' do
    let(:user) { User.anonymous }

    describe "#logo_download" do
      render_views

      before do
        expect(CustomStyle).to receive(:current).and_return(custom_style)
        allow(controller).to receive(:send_file) { controller.head 200 }
        get :logo_download, params: { digest: "1234", filename: "logo_image.png" }
      end

      context "when logo is present" do
        let(:custom_style) { FactoryGirl.build(:custom_style_with_logo) }

        it 'will send a file' do
          expect(response.status).to eq(200)
        end
      end

      context "when no logo is present" do
        let(:custom_style) { nil }

        it 'renders with error' do
          expect(controller).to_not receive(:send_file)
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
