module UrlHelper
  def url_for_with_params(**args)
    query = request.query_parameters
    url_for(**query.merge(args))
  end
end
