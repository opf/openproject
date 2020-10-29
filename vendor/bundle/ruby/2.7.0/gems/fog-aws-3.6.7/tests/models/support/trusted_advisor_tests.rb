Shindo.tests("AWS::Support | trusted_advisor_checks", ["aws", "support"]) do
  tests("collection#all").succeeds do
    Fog::AWS[:support].trusted_advisor_checks.all
  end

  @identity = Fog::AWS[:support].trusted_advisor_checks.all.first.identity

  tests("collection#get(#{@identity})").returns(@identity) do
    Fog::AWS[:support].trusted_advisor_checks.get(@identity).identity
  end

  @model = Fog::AWS[:support].trusted_advisor_checks.all.detect { |tac| tac.id == @identity }

  tests("model#flagged_resources").returns(nil) do
    @model.flagged_resources
  end

  tests("model#flagged_resources").returns(true) do
    @model.flagged_resources(false).is_a?(Fog::AWS::Support::FlaggedResources)
  end

  tests("model#flagged_resources").returns(true) do
    @model.flagged_resources.first.metadata.keys.sort == @model.metadata.sort
  end
end
