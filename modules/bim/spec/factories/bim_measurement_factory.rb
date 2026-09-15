# frozen_string_literal: true

FactoryBot.define do
  factory :bim_measurement, class: 'Bim::Measurement' do
    association :ifc_model, factory: :ifc_model
    association :user, factory: :user

    measurement_type { 'distance' }
    value { 10.0 }
    unit { 'm' }
    points { [[0.0, 0.0, 0.0], [10.0, 0.0, 0.0]] }
    visible { true }
    color { '#FF0000' }
    line_width { 2.0 }

    trait :distance do
      measurement_type { 'distance' }
      value { 15.5 }
      unit { 'm' }
      points { [[0.0, 0.0, 0.0], [10.0, 5.0, 5.0]] }
      label { 'Wall Length' }
    end

    trait :multi_segment_distance do
      measurement_type { 'distance' }
      value { 25.0 }
      unit { 'm' }
      points do
        [
          [0.0, 0.0, 0.0],
          [10.0, 0.0, 0.0],
          [10.0, 10.0, 0.0],
          [0.0, 10.0, 0.0]
        ]
      end
      label { 'Perimeter' }
    end

    trait :area do
      measurement_type { 'area' }
      value { 100.0 }
      unit { 'm²' }
      points do
        [
          [0.0, 0.0, 0.0],
          [10.0, 0.0, 0.0],
          [10.0, 0.0, 10.0],
          [0.0, 0.0, 10.0]
        ]
      end
      label { 'Floor Area' }
    end

    trait :volume do
      measurement_type { 'volume' }
      value { 1000.0 }
      unit { 'm³' }
      points { [[0.0, 0.0, 0.0], [10.0, 10.0, 10.0]] }
      label { 'Room Volume' }
    end

    trait :angle do
      measurement_type { 'angle' }
      value { 90.0 }
      unit { 'degrees' }
      points do
        [
          [0.0, 0.0, 0.0], # vertex
          [1.0, 0.0, 0.0], # direction 1
          [0.0, 1.0, 0.0]  # direction 2
        ]
      end
      label { 'Corner Angle' }
    end

    trait :elevation do
      measurement_type { 'elevation' }
      value { 3.5 }
      unit { 'm' }
      points { [[0.0, 3.5, 0.0]] }
      label { 'Floor Level' }
    end

    trait :hidden do
      visible { false }
    end

    trait :with_metadata do
      metadata do
        {
          'calculation_method' => 'direct',
          'precision' => 'high',
          'reference_point' => [0, 0, 0]
        }
      end
    end
  end
end
