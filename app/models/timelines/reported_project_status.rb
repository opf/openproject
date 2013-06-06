class Timelines::ReportedProjectStatus < Enumeration

  extend Timelines::Pagination::Model

  unloadable

  scope :like, lambda { |q|
    s = "%#{q.to_s.strip.downcase}%"
    { :conditions => ["LOWER(name) LIKE :s", {:s => s}],
    :order => "name" }
  }

  has_many :reportings, :class_name  => "Timelines::Reporting",
                        :foreign_key => 'reported_project_status_id'

  OptionName = :enumeration_reported_project_statuses

  def option_name
    OptionName
  end

  def objects_count
    reportings.count
  end

  def transfer_relations(to)
    reportings.update.all(:reported_project_status_id => to.id)
  end

  def self.search_scope(query)
    like(query)
  end
end
