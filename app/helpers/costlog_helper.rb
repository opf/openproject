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
    cost_types = CostType.find(:all, :conditions => {:deleted_at => nil}).sort

    if selected_type && !cost_types.include?(selected_type)
      cost_types << selected_type
      cost_types.sort
    end
    collection = []
    collection << [ "--- #{l(:actionview_instancetag_blank_option)} ---", '' ] unless cost_types.detect(&:is_default?)
    cost_types.each { |t| collection << [t.name, t.id] }
    collection
  end
  
  def user_collection_for_select_options(options = {})
    users = @project.assignable_users
    collection = []
    users.each { |u| collection << [u.name, u.id] }
    collection
  end
  
  def entries_to_csv(entries)
    # TODO
    raise( NotImplementedError, "entries_to_csv is not implemented yet" )

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
                  User.current.allowed_to?(:view_cost_rates, entry.project) ? entry.cost_type.unit_price.to_s.gsub('.', decimal_separator): "-",
                  entry.units.to_s.gsub('.', decimal_separator),
                  User.current.allowed_to?(:view_cost_rates, entry.project) ? entry.cost.to_s.gsub('.', decimal_separator): "-"
                  ]

        csv << fields.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      end
    end
    export.rewind
    export
  end
  
  def extended_progress_bar(pcts, options={})
    return progress_bar(pcts, options) unless pcts.is_a?(Numeric) && pcts > 100
    
    width = options[:width] || '100px;'
    legend = options[:legend] || ''
    content_tag('table',
      content_tag('tr',
        content_tag('td', '', :style => "width: #{((100.0 / pcts) * 100).round}%;", :class => 'closed') +
        content_tag('td', '', :style => "width: #{100.0 - ((100.0 / pcts) * 100).round}%;", :class => 'exceeded')
      ), :class => 'progress', :style => "width: #{width};") +
      content_tag('p', legend, :class => 'pourcent')
  end
  
  def clean_currency(value)
    return nil if value.nil? || value == ""

    value = value.strip
    value.gsub!(l(:currency_delimiter), '') if value.include?(l(:currency_delimiter)) && value.include?(l(:currency_separator))
    value.gsub(',', '.')
    BigDecimal.new(value)
  end
end
  