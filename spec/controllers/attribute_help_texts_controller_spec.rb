require 'spec_helper'

describe AttributeHelpTextsController, type: :controller do
  let(:model) { FactoryGirl.build :work_package_help_text }
  let(:relation_columns_allowed) { true }

  let(:find_expectation) do
    allow(AttributeHelpText)
      .to receive(:find)
      .with(1234.to_s)
      .and_return(model)
  end

  before do
    allow(EnterpriseToken)
      .to receive(:allows_to?)
      .with(:attribute_help_texts)
      .and_return(relation_columns_allowed)

    expect(controller).to receive(:require_admin)
  end

  describe '#index' do
    before do
      allow(AttributeHelpText).to receive(:all).and_return [model]

      get :index
    end

    it 'is successful' do
      expect(response).to be_success
      expect(assigns(:texts_by_type)).to eql('WorkPackage' => [model])
    end

    context 'with help texts disallowed by the enterprise token' do
      let(:relation_columns_allowed) { false }

      it 'returns 404' do
        expect(response.status).to eql 404
      end
    end
  end

  describe '#edit' do
    before do
      find_expectation

      get :edit, params: { id: 1234 }
    end

    context 'when found' do
      it 'is successful' do
        expect(response).to be_success
        expect(assigns(:attribute_help_text)).to eql model
      end
    end

    context 'with help texts disallowed by the enterprise token' do
      let(:relation_columns_allowed) { false }

      it 'returns 404' do
        expect(response.status).to eql 404
      end
    end

    context 'when not found' do
      let(:find_expectation) do
        allow(AttributeHelpText)
          .to receive(:find)
          .with(1234.to_s)
          .and_raise(ActiveRecord::RecordNotFound)
      end

      it 'returns 404' do
        expect(response.status).to eq 404
      end
    end
  end

  describe '#update' do
    let(:call) do
      put :update,
          params: {
            id: 1234,
            attribute_help_text: {
              help_text: 'my new help text'
            }
          }
    end

    before do
      find_expectation
    end

    context 'when save is success' do
      before do
        expect(model).to receive(:save).and_return(true)

        call
      end

      it 'edits the announcement' do
        expect(response).to redirect_to action: :index, tab: 'WorkPackage'
        expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_update)

        expect(model.help_text).to eq('my new help text')
      end
    end

    context 'when save is failure' do
      before do
        expect(model).to receive(:save).and_return(false)

        call
      end

      it 'fails to update the announcement' do
        expect(response).to be_success
        expect(response).to render_template 'edit'
      end
    end

    context 'when not found' do
      let(:find_expectation) do
        allow(AttributeHelpText)
          .to receive(:find)
          .with(1234.to_s)
          .and_raise(ActiveRecord::RecordNotFound)
      end

      before do
        call
      end

      it 'returns 404' do
        expect(response.status).to eq 404
      end
    end

    context 'with help texts disallowed by the enterprise token' do
      let(:relation_columns_allowed) { false }

      before do
        call
      end

      it 'returns 404' do
        expect(response.status).to eql 404
      end
    end
  end
end
