module OpenProject::Documents::Patches
  module ProjectPatch
    def self.included(base)
      base.class_eval do

        has_many :documents, :dependent => :destroy
      end
    end
  end
end

Project.send(:include, OpenProject::Documents::Patches::ProjectPatch)
