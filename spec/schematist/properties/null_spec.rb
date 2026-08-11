# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "null properties" do
  let(:schema_class) { Class.new(described_class) }

  it "supports null type with description" do
    schema_class.null :placeholder, description: "Null field"

    properties = schema_class.properties
    expect(properties[:placeholder]).to eq({type: "null", description: "Null field"})
  end

  it "supports null enum values" do
    schema_class.null :nothing, enum: [nil]

    expect(schema_class.properties[:nothing]).to eq({type: "null", enum: [nil]})
  end
end
