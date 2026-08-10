# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "null properties" do
  let(:schema_class) { Class.new(described_class) }

  it "supports null type with description" do
    schema_class.null :placeholder, description: "Null field"

    properties = schema_class.properties
    expect(properties[:placeholder]).to eq({type: "null", description: "Null field"})
  end
end
