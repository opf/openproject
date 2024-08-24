require "spec_helper"

RSpec.describe AttributeHelpTextsController do
  let(:user) { build_stubbed(:user) }
  let(:model) { build(:work_package_help_text) }

  let(:find_expectation) do
    allow(AttributeHelpText)
      .to receive(:find)
      .with(1234.to_s)
      .and_return(model)
  end

  before do
    login_as user

    mock_permissions_for(user) do |mock|
      mock.allow_globally :edit_attribute_help_texts
    end
  end

  describe "#index" do
    before do
      allow(AttributeHelpText).to receive(:all).and_return [model]

      get :index
    end

    it "is successful" do
      expect(response).to be_successful
      expect(assigns(:texts_by_type)).to eql("WorkPackage" => [model])
    end
  end

  describe "#edit" do
    before do
      find_expectation

      get :edit, params: { id: 1234 }
    end

    context "when found" do
      it "is successful" do
        expect(response).to be_successful
        expect(assigns(:attribute_help_text)).to eql model
      end
    end

    context "when not found" do
      let(:find_expectation) do
        allow(AttributeHelpText)
          .to receive(:find)
          .with(1234.to_s)
          .and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns 404" do
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "#update" do
    let(:call) do
      put :update,
          params: {
            id: 1234,
            attribute_help_text: {
              help_text: "my new help text"
            }
          }
    end

    before do
      find_expectation
    end

    context "when save is success" do
      before do
        expect(model).to receive(:save).and_return(true)

        call
      end

      it "edits the announcement" do
        expect(response).to redirect_to action: :index, tab: "WorkPackage"
        expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_update)

        expect(model.help_text).to eq("my new help text")
      end
    end

    context "when save is failure" do
      before do
        expect(model).to receive(:save).and_return(false)

        call
      end

      it "fails to update the announcement" do
        expect(response).to be_successful
        expect(response).to render_template "edit"
      end
    end

    context "when not found" do
      let(:find_expectation) do
        allow(AttributeHelpText)
          .to receive(:find)
          .with(1234.to_s)
          .and_raise(ActiveRecord::RecordNotFound)
      end

      before do
        call
      end

      it "returns 404" do
        expect(response).to have_http_status :not_found
      end
    end
  end
end
