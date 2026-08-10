# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "oneOf properties" do
  let(:schema_class) { Class.new(described_class) }

  it "supports one_of with mixed types including objects" do
    schema_class.one_of :exclusive_field do
      string enum: %w[option1 option2]
      integer
      object do
        string :nested_field
      end
      null
    end

    properties = schema_class.properties
    one_of_schemas = properties[:exclusive_field][:oneOf]

    expect(one_of_schemas).to include(
      {type: "string", enum: %w[option1 option2]},
      {type: "integer"},
      {type: "null"}
    )

    object_schema = one_of_schemas.find { |schema| schema[:type] == "object" }
    expect(object_schema[:properties][:nested_field]).to eq({type: "string"})
  end

  it "supports arrays of oneOf types" do
    schema_class.array :items do
      one_of :value do
        string :alphanumeric
        number :numeric
      end
    end

    one_of_schemas = schema_class.properties[:items][:items][:oneOf]
    expect(one_of_schemas.map { |schema| schema[:type] }).to include("string", "number")
  end

  it "supports basic oneOf with primitive types" do
    schema_class.one_of :status do
      string enum: %w[active inactive]
      integer
      boolean
    end

    properties = schema_class.properties
    one_of_schemas = properties[:status][:oneOf]

    expect(one_of_schemas).to include(
      {type: "string", enum: %w[active inactive]},
      {type: "integer"},
      {type: "boolean"}
    )
  end
end
