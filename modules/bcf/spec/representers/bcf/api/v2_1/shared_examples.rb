shared_examples_for 'attribute' do
  it 'reflects the project' do
    expect(subject)
      .to be_json_eql(value.to_json)
            .at_path(path)
  end
end

