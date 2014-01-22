module OpenProject::Costs::Patches::ProjectPatch
  def self.included(base) # :nodoc:
    # Same as typing in the class
    base.class_eval do
      unloadable

      has_many :cost_objects, :dependent => :destroy
      has_many :rates, :class_name => 'HourlyRate'

      has_many :member_groups, :class_name => 'Member',
                               :include => :principal,
                               :conditions => "#{Principal.table_name}.type='Group'"
      has_many :groups, :through => :member_groups, :source => :principal
    end

  end
end
