
object @query => :query

attributes :id, :name

node(:_links) { @query_links }
