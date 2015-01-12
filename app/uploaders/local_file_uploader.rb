class LocalFileUploader < CarrierWave::Uploader::Base
  include FileUploader

  storage :file

  def store_dir
    dir = "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    OpenProject::Configuration.attachments_storage_path.join(dir)
  end
end
