class CustomStyle < ApplicationRecord
  mount_uploader :logo, OpenProject::Configuration.file_uploader
  mount_uploader :export_logo, OpenProject::Configuration.file_uploader
  mount_uploader :export_cover, OpenProject::Configuration.file_uploader
  mount_uploader :favicon, OpenProject::Configuration.file_uploader
  mount_uploader :touch_icon, OpenProject::Configuration.file_uploader

  class << self
    def current
      RequestStore.fetch(:current_custom_style) do
        custom_style = CustomStyle.order(Arel.sql('created_at DESC')).first
        if custom_style.nil?
          return nil
        else
          custom_style
        end
      end
    end
  end

  def digest
    updated_at.to_i
  end

  %i(favicon touch_icon export_logo export_cover logo).each do |name|
    define_method :"#{name}_path" do
      image = send(name)

      if image.readable?
        image.local_file.path
      end
    end

    define_method :"remove_#{name}" do
      image = send(name)
      image&.remove!

      update_column name, nil
    end
  end
end
