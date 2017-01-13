class CustomStyle < ActiveRecord::Base
  mount_uploader :logo, OpenProject::Configuration.file_uploader

  class << self
    def current
      if RequestStore.store[:current_custom_style].present?
        return RequestStore.store[:current_custom_style]
      else
        custom_style = CustomStyle.order('created_at DESC').first
        if custom_style.nil?
          return nil
        else
          RequestStore.store[:current_custom_style] = custom_style
        end
      end
    end
  end

  def digest
    updated_at.to_i
  end
end
