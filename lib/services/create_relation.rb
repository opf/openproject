class Services::CreateRelation
  def initialize(from_work_package, to_work_package, attrs = {})
    @relation = from_work_package.new_relation.tap do |r|
      r.to = to_work_package
      r.relation_type = attrs[:relation_type]
      r.delay = attrs[:delay]
    end
  end

  def run(success = -> {}, failure = -> {})
    if @relation.save
      success.(created: true)
    else
      binding.pry
      error.(@relation)
    end
  end
end
