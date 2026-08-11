# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "numeric properties" do
  let(:schema_class) { Class.new(described_class) }

  it "supports number type with constraints" do
    schema_class.number :price, minimum: 0, maximum: 1000, multiple_of: 0.01, description: "Price field"

    properties = schema_class.properties
    expect(properties[:price]).to eq({
      type: "number",
      minimum: 0,
      maximum: 1000,
      multipleOf: 0.01,
      description: "Price field"
    })
  end

  it "supports number enum values" do
    schema_class.number :score, enum: [0.5, 1.5]

    properties = schema_class.properties
    expect(properties[:score]).to eq({type: "number", enum: [0.5, 1.5]})
  end

  it "supports number const values" do
    schema_class.number :version, const: 1.5

    properties = schema_class.properties
    expect(properties[:version]).to eq({type: "number", const: 1.5})
  end

  it "supports exclusive number boundaries" do
    schema_class.number :score, greater_than: 0, less_than: 100

    properties = schema_class.properties
    expect(properties[:score]).to eq({
      type: "number",
      exclusiveMinimum: 0,
      exclusiveMaximum: 100
    })
  end

  it "supports number type with description" do
    schema_class.number :price, description: "Price field"

    properties = schema_class.properties
    expect(properties[:price]).to eq({type: "number", description: "Price field"})
  end

  it "supports integer type with description" do
    schema_class.integer :count, description: "Count value"

    properties = schema_class.properties
    expect(properties[:count]).to eq({type: "integer", description: "Count value"})
  end

  it "supports integer const values" do
    schema_class.integer :version, const: 1

    properties = schema_class.properties
    expect(properties[:version]).to eq({type: "integer", const: 1})
  end

  it "supports exclusive integer boundaries" do
    schema_class.integer :age, greater_than: 17, less_than: 66

    properties = schema_class.properties
    expect(properties[:age]).to eq({
      type: "integer",
      exclusiveMinimum: 17,
      exclusiveMaximum: 66
    })
  end

  it "supports integer enum values" do
    schema_class.integer :level, enum: [0, 1, 2]

    properties = schema_class.properties
    expect(properties[:level]).to eq({type: "integer", enum: [0, 1, 2]})
  end

  it "supports format on numeric types" do
    schema_class.integer :id, format: "int64"
    schema_class.number :ratio, format: "double"

    expect(schema_class.properties[:id]).to eq({type: "integer", format: "int64"})
    expect(schema_class.properties[:ratio]).to eq({type: "number", format: "double"})
  end
end
