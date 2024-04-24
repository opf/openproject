module OpenProject::Bim::Patches::FogFileUploaderPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def fog_attributes
      return super unless path.ends_with?(".bcf")

      super.merge({
                    "Content-Type" => "application/octet-stream"
                  })
    end
  end
end
