# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "anyOf properties" do
  let(:schema_class) { Class.new(described_class) }

  it "supports any_of with mixed types including objects" do
    schema_class.any_of :flexible_field do
      string enum: %w[option1 option2]
      integer
      object do
        string :nested_field
      end
      null
    end

    properties = schema_class.properties
    any_of_schemas = properties[:flexible_field][:anyOf]

    expect(any_of_schemas).to include(
      {type: "string", enum: %w[option1 option2]},
      {type: "integer"},
      {type: "null"}
    )

    object_schema = any_of_schemas.find { |schema| schema[:type] == "object" }
    expect(object_schema[:properties][:nested_field]).to eq({type: "string"})
  end

  it "supports arrays of anyOf types" do
    schema_class.array :items do
      any_of :value do
        string :alphanumeric
        number :numeric
      end
    end

    any_of_schemas = schema_class.properties[:items][:items][:anyOf]
    expect(any_of_schemas.map { |schema| schema[:type] }).to include("string", "number")
  end
end
