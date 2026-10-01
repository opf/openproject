# frozen_string_literal: true

require "rails_helper"

RSpec.describe OpTurbo::FlashStreamHelper do
  described_module = described_class

  controller(ApplicationController) do
    include described_module

    no_authorization_required! :update

    def update
      flash_component = OpPrimer::FlashComponent
        .new(scheme: :success)
        .with_content("Saved")

      respond_with_flash(flash_component)
    end
  end

  current_user { build_stubbed(:user) }

  before do
    routes.draw { get "update" => "anonymous#update" }
  end

  it "renders an announcing flash stream" do
    get :update, as: :turbo_stream

    expect(response.body).to include '<turbo-stream action="flash"'
    expect(response.body).to include 'data-announcement="Saved"'
    expect(response.body).to include 'data-politeness="polite"'
    expect(response.body).not_to include 'action="liveRegion"'
  end
end
