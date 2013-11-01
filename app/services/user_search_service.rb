class UserSearchService
  attr_accessor :params

  def initialize(params)
    self.params = params
  end

  def search
    scope = User
    params[:ids].present? ? ids_search(scope) : query_search(scope)
  end

  def ids_search(scope)
    ids = params[:ids].split(',')

    scope.where(:id => ids)
  end

  def query_search(scope)
    scope = scope.in_group(params[:group_id].to_i) if params[:group_id].present?
    c = ARCondition.new

    if params[:status] == 'blocked'
      @status = :blocked
      scope = scope.blocked
    elsif params[:status] == 'all'
      @status = :all
      scope = scope.not_builtin
    else
      @status = params[:status] ? params[:status].to_i : User::STATUSES[:active]
      scope = scope.not_blocked if @status == User::STATUSES[:active]
      c << ["status = ?", @status]
    end

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
    end

    scope.where(c.conditions)
                # currently, the sort/paging-helpers are highly dependent on being included in a controller
                # and having access to things like the session or the params: this makes it harder
                # to test outside a controller and especially hard to re-use this functionality
                #.page(page_param)
                #.per_page(per_page_param)
                # .order(sort_clause)
  end

end