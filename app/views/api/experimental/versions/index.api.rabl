
collection @versions => :versions
attributes id: :id
node(:name) do |version|
  if version.project == @project
    version.name
  else
    version.to_s_with_project
  end
end
