# frozen_string_literal: true

module MetaTags
  class Railtie < Rails::Railtie
    initializer 'meta_tags.setup_action_controller' do
      ActiveSupport.on_load :action_controller do
        ActionController::Base.include MetaTags::ControllerHelper
      end
    end

    initializer 'meta_tags.setup_action_view' do
      ActiveSupport.on_load :action_view do
        ActionView::Base.include MetaTags::ViewHelper
      end
    end
  end
end
