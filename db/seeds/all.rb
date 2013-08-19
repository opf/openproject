# add seeds here, that need to be available in all environments
unless Type.exists?(name: "none")
  Type.connection.schema_cache.clear!
  Type.reset_column_information
  Type.create!(name: 'none',
               color_id: '#000000',
               is_standard: true,
               is_default: true,
               is_in_chlog: true,
               is_in_roadmap: true,
               in_aggregation: true,
               is_milestone: false)
end