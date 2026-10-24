# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Queries::Meetings::Filters::UpdatedAtFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :datetime_past }
    let(:class_key) { :updated_at }

    describe "#available?" do
      it "is true" do
        expect(instance).to be_available
      end
    end

    describe "#allowed_values" do
      it "is nil" do
        expect(instance.allowed_values).to be_nil
      end
    end

    it_behaves_like "non ar filter"
  end
end
