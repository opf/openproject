# add seeds here, that need to be available in all environments

[Type, PlanningElementTypeColor].each do |klass|
  klass.connection.schema_cache.clear!
  klass.reset_column_information
end

PlanningElementTypeColor.ms_project_colors.map(&:save)
default_color = PlanningElementTypeColor.find_by_name('pjSilver')

Type.find_or_create_by_is_standard(true, name: 'none',
                                         color_id: default_color.id,
                                         is_default: true,
                                         is_in_chlog: true,
                                         is_in_roadmap: true,
                                         in_aggregation: true,
                                         is_milestone: false)
