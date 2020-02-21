module OpenProject::Bim::Patches::RootSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def seed_basic_data
      ::Bim::BasicDataSeeder.new.seed!
    end
  end
end
