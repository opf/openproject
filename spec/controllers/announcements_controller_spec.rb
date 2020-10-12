require 'spec_helper'

describe AnnouncementsController, type: :controller do
  let(:announcement) { FactoryBot.build :announcement }
  before do
    allow(controller).to receive(:check_if_login_required)
    expect(controller).to receive(:require_admin)

    allow(Announcement).to receive(:only_one).and_return(announcement)
  end

  describe '#edit' do
    before do
      get :edit
    end

    it do expect(assigns(:announcement)).to eql announcement end
    it { expect(response).to be_successful }
  end

  describe '#update' do
    before do
      expect(announcement).to receive(:save).and_call_original
      put :update,
          params: {
            announcement: {
              until_date: '2011-01-11',
              text: 'announcement!!!',
              active: 1
            }
          }
    end

    it 'edits the announcement' do
      expect(response).to redirect_to action: :edit
      expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_update)
    end
  end
end
