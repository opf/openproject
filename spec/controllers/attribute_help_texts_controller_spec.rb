require 'spec_helper'

describe AttributeHelpTextsController, type: :controller do
  let(:model) { FactoryGirl.build :work_package_help_text }
  before do
    expect(controller).to receive(:require_admin)
  end

  describe '#index' do
    before do
      allow(AttributeHelpText).to receive(:all).and_return [model]

      get :index
    end

    it do
      expect(response).to be_success
      expect(assigns(:texts_by_type)).to eql('WorkPackage' => [model])
    end
  end

  describe '#edit' do
    context 'when not found'
    before do
      get :edit, params: { id: 1234 }
    end

    it do
      expect(response.status).to eq 404
    end
  end

  context 'when found' do
    before do
      allow(AttributeHelpText).to receive(:find).and_return(model)

      get :edit
    end

    it do
      expect(response).to be_success
      expect(assigns(:attribute_help_text)).to eql model
    end
  end

  describe '#update' do
    before do
      allow(AttributeHelpText).to receive(:find).and_return(model)
      expect(model).to receive(:save).and_return(success)
      put :update,
          params: {
            attribute_help_text: {
              help_text: 'my new help text'
            }
          }
    end

    context 'when save is failure' do
      let(:success) { false }
      it 'fails to update the announcement' do
        expect(response).to be_success
        expect(response).to render_template 'edit'
      end
    end

    context 'when save is success' do
      let(:success) { true }
      it 'edits the announcement' do
        expect(response).to redirect_to action: :index, tab: 'WorkPackage'
        expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_update)

        expect(model.help_text).to eq('my new help text')
      end
    end
  end
end
