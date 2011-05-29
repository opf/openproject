class EnabledModule < ActiveRecord::Base
  belongs_to :project
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :project_id
  
  after_create :module_enabled
  
  private
  
  # after_create callback used to do things when a module is enabled
  def module_enabled
    case name
    when 'wiki'
      # Create a wiki with a default start page
      if project && project.wiki.nil?
        Wiki.create(:project => project, :start_page => 'Wiki')
      end
    end
  end
end
