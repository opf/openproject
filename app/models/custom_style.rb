class CustomStyle < ActiveRecord::Base
  mount_uploader :logo, OpenProject::Configuration.file_uploader

  def self.current
    CustomStyle.order('created_at DESC').first
  end

  def digest
    updated_at.to_i
  end
end
