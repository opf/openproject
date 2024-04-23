Gem::Specification.new do |s|
  s.name        = "openproject-avatars"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.summary     = "OpenProject Avatars"
  s.description = "This plugin allows OpenProject users to upload a picture to be used " \
                  "as an avatar or use registered images from Gravatar."
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(README.md)

  s.add_dependency "fastimage", "~> 2.3.0"
  s.add_dependency "gravatar_image_tag", "~> 1.2.0"
  s.metadata["rubygems_mfa_required"] = "true"
end
