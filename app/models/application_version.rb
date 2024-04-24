class ApplicationVersion < ApplicationRecord
  include PaperTrail::VersionConcern
end
