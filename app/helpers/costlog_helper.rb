module CostlogHelper
  include TimelogHelper
  
  def render_costlog_breadcrumb
    links = []
    links << link_to(l(:label_project_all), {:project_id => nil, :issue_id => nil})
    links << link_to(h(@project), {:project_id => @project, :issue_id => nil}) if @project
    links << link_to_issue(@issue) if @issue
    breadcrumb links
  end
  
  def cost_types_collection_for_select_options(selected_type = nil)
    cost_types = CostType.all.sort
    collection = []
    collection << [ "--- #{l(:actionview_instancetag_blank_option)} ---", '' ] unless cost_types.detect(&:is_default)
    cost_types.each { |t| collection << [t.name, t.id] }
    collection
  end
  
  def user_collection_for_select_options(options = {})
    users = @project.assignable_users
    collection = []
    # This is an optional extension
    #collection << [l(:label_generic_user), 0] if options[:generic_user]
    users.each { |u| collection << [u.name, u.id] }
    collection
  end
  
  def entries_to_csv(entries)
    ic = Iconv.new(l(:general_csv_encoding), 'UTF-8')    
    decimal_separator = l(:general_csv_decimal_separator)
    export = StringIO.new
    CSV::Writer.generate(export, l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [l(:field_spent_on),
                 l(:field_user),
                 l(:field_project),
                 l(:field_issue),
                 l(:field_tracker),
                 l(:field_subject),
                 l(:field_comments),
                 l(:field_cost_type),
                 l(:field_unit_price),
                 l(:field_units),
                 l(:field_overall_costs)
                 ]
      
      csv << headers.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      # csv lines
      entries.each do |entry|
        fields = [format_date(entry.spent_on),
                  entry.user,
                  entry.project,
                  (entry.issue ? entry.issue.id : nil),
                  (entry.issue ? entry.issue.tracker : nil),
                  (entry.issue ? entry.issue.subject : nil),
                  entry.comments,
                  entry.cost_type.name,
                  User.current.allowed_to?(:view_unit_price, entry.project) ? entry.cost_type.unit_price.to_s.gsub('.', decimal_separator): "-",
                  entry.units.to_s.gsub('.', decimal_separator),
                  User.current.allowed_to?(:view_unit_price, entry.project) ? entry.cost.to_s.gsub('.', decimal_separator): "-"
                  ]

        csv << fields.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      end
    end
    export.rewind
    export
  end
  
end
  