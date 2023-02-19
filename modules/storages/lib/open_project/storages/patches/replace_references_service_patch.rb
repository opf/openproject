module OpenProject::Storages::Patches::ReplaceReferencesServicePatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    private

    def rewrite_active_models(from, to)
      super
      rewrite_creator(from, to)
    end

    def rewrite_creator(from, to)
      [::Storages::Storage,
       ::Storages::ProjectStorage,
       ::Storages::FileLink].each do |klass|
        klass.where(creator_id: from.id).update_all(creator_id: to.id)
      end
    end
  end
end
