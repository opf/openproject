class PlanningComparisonService
  @@journal_sql = <<SQL
      select #{Journal.table_name}.id
        from journals
         inner join (select journable_id, max(created_at) as latest_date
                       from #{Journal.table_name}
                      where #{Journal.table_name}.created_at <= ?
                   group by #{Journal.table_name}.journable_id) as latest
                 on #{Journal.table_name}.journable_id=latest.journable_id
           and #{Journal.table_name}.created_at=latest.latest_date
           and #{Journal.table_name}.journable_id in (?);
SQL
  @@mapped_attributes = Journal::WorkPackageJournal.journaled_attributes.map{|attribute| "#{Journal::WorkPackageJournal.table_name}.#{attribute}"}.join ','

  @@work_package_select = <<SQL
      Select #{Journal.table_name}.journable_id as id,
             #{Journal.table_name}.created_at as created_at,
             #{Journal.table_name}.created_at as updated_at,
             #{@@mapped_attributes}
        from #{Journal::WorkPackageJournal.table_name}
        left join #{Journal.table_name}
               on #{Journal.table_name}.id = #{Journal::WorkPackageJournal.table_name}.journal_id
       where #{Journal::WorkPackageJournal.table_name}.journal_id in (?)
SQL

  # there is currently no possibility to compare two given dates:
  # the comparison always works on the current date, filters the current workpackages
  # and returns the state of these work_packages at the given time
  # filters are given in the format expected by Query and are just passed through to query
  def self.compare(projects, at_time, filter={})

    # The query uses three steps to find the journalized entries for the filtered workpackages
    # at the given point in time:
    # 1 filter the ids using query
    # 2 find out the latest journal-entries for the given date belonging to the filtered ids
    # 3 fetch the data for these journals from Journal::WorkPackageData
    # 4 fill theses journal-data into a workpackage

    # 1 either filter the ids using the given filter or pluck all work_package-ids from the project
    work_package_ids = if filter.has_key? :f
                         work_package_scope = WorkPackage.scoped
                                                         .joins(:status)
                                                         .joins(:project) #no idea, why query doesn't provide these joins itself...
                                                         .for_projects(projects)
                                                         .without_deleted

                         query = Query.new
                         query.add_filters(filter[:f], filter[:op], filter[:v])
                         #TODO teach query to fetch only ids
                         work_package_scope.with_query(query)
                                           .pluck(:id)
                       else
                         WorkPackage.for_projects(projects).pluck(:id)
                       end

    # 2 fetch latest journal-entries for the given time
    journal_ids = Journal.find_by_sql([@@journal_sql, at_time, work_package_ids])
                         .map(&:id)

    # 3&4 fetch the journaled data and make rails think it is actually a work_package
    work_packages = WorkPackage.find_by_sql([@@work_package_select,journal_ids])


  end
end