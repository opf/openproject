class FlipBcfViewpointClippingDirectionSelectively < ActiveRecord::Migration[6.1]
  def up
    flip_op_clipping_planes
  end

  def down
    flip_op_clipping_planes
  end

  private

  def flip_op_clipping_planes
    viewpoints = select_viewpoints_created_in_op
    viewpoints.each do |viewpoint|
      new_json_viewpoint = flip_clipping_planes(viewpoint.json_viewpoint)
      viewpoint.update_column(:json_viewpoint, new_json_viewpoint)
    end
  end

  def select_viewpoints_created_in_op
    join_condition = %{
      bcf_viewpoints.json_viewpoint->>'clipping_planes' IS NOT NULL
      AND
      (
        bcf_issues.markup IS NULL
        OR
        XPATH_EXISTS('/comment()[contains(., ''Created by OpenProject'')]', bcf_issues.markup)
      )
    }
    ::Bim::Bcf::Viewpoint.joins(:issue).where(join_condition)
  end

  def flip_clipping_planes(viewpoint)
    viewpoint_dup = viewpoint.deep_dup
    viewpoint_dup["clipping_planes"].each do |plane|
      plane["direction"]["x"] *= -1
      plane["direction"]["y"] *= -1
      plane["direction"]["z"] *= -1
    end

    viewpoint_dup
  end
end
