class CostQuery < Report
  def_delegators :result, :real_costs

  User.before_destroy do |user|
    CostQuery.delete_all ['user_id = ? AND is_public = ?', user.id, false]
    CostQuery.update_all ['user_id = ?', DeletedUser.first.id], ['user_id = ?', user.id]

    max_query_id = 0
    while((current_queries = CostQuery.all(:limit => 1000,
                                           :conditions => ["id > ?", max_query_id],
                                           :order => "id ASC")).size > 0) do

      current_queries.each do |query|
        serialized = query.serialized

        serialized[:filters] = serialized[:filters].map do |name, options|
          options[:values].delete(user.id.to_s) if ["UserId", "AuthorId", "AssignedToId"].include?(name)

          options[:values].nil? || options[:values].size > 0 ?
            [name, options] :
            nil
        end.compact

        CostQuery.update_all ["serialized = ?", YAML::dump(serialized)], ["id = ?", query.id]

        max_query_id = query.id
      end
    end
  end
end

