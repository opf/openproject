require_dependency 'query'

class CostQueryColumn < QueryColumn
  attr_accessor :name, :sortable, :groupable, :default_order
  
  def initialize(name, options={})
    self.type = (optione.delete(:type) || 'issue')
    super
  end
end

class CostQuery < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  
  serialize :filters
  serialize :group_by
  
  attr_protected :user_id, :project_id, :created_at, :updated_at
  
  def self.operators
    Query.operators
  end
  
  def operators_by_filter_type
    Query.operators_by_filter_type
  end
  
  def available_filters
    # This available_filters is different from the Redmine one
    # available_filters[:issues]
    #     --> filters on issue fields. These are the one from redmine itself
    # available_filters[:costs]
    #    --> filters on cost and time entries
    
    return @available_filters if @available_filters
    
    @available_filters = {
      :costs => {
        "cost_type_id" => { :type => :list_optional, :order => 2, :applies => [:cost_entries], :values => CostType.find(:all, :order => 'name').collect{|s| [s.name, s.id.to_s] }},
        "activity" => { :type => :list_optional, :order => 3, :applies => [:time_entries], :values => Enumeration.find(:all, :conditions => ['opt=?','ACTI'], :order => 'position').collect{|s| [s.name, s.id.to_s] }},
        "created_on" => { :type => :date_past, :applies => [:time_entries, :cost_entries], :order => 4 },                        
        "updated_on" => { :type => :date_past, :applies => [:time_entries, :cost_entries], :order => 5 },
        "spent_on" => { :type => :date, :applies => [:time_entries, :cost_entries], :order => 6 }
        "overridden" => { :type => }
      },
    }
    
    tmp_query = Query.new(:project => project)
    @available_filters[:issues] = tmp_query.available_filters
    
    if @available_filters[:issues]["author_id"]
      # add a filter on cost entries for user_id if it is available
      user_values = @available_filters[:issues]["author_id"][:values]
      @available_filters[:costs]["user_id"] = {:type => :list_optional, :order => 1, :applies => [:time_entries, :cost_entries], :values => user_values}
    end
    
    @available_filters
  end
  
end
