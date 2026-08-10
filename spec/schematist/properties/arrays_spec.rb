# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "array properties" do
  let(:schema_class) { Class.new(described_class) }

  it "supports arrays with primitive types and descriptions" do
    schema_class.array :strings, of: :string, description: "String array"
    schema_class.array :numbers, of: :number
    schema_class.array :integers, of: :integer
    schema_class.array :booleans, of: :boolean

    properties = schema_class.properties

    expect(properties[:strings]).to eq({type: "array", items: {type: "string"}, description: "String array"})
    expect(properties[:numbers]).to eq({type: "array", items: {type: "number"}})
    expect(properties[:integers]).to eq({type: "array", items: {type: "integer"}})
    expect(properties[:booleans]).to eq({type: "array", items: {type: "boolean"}})
  end

  it "supports arrays with constraints" do
    schema_class.array :strings, of: :string, min_items: 1, max_items: 10, description: "String array"

    properties = schema_class.properties
    expect(properties[:strings]).to eq({type: "array", items: {type: "string"}, minItems: 1, maxItems: 10, description: "String array"})
  end

  it "supports arrays with object definitions" do
    schema_class.array :items do
      object do
        string :name
        integer :value
      end
    end

    properties = schema_class.properties
    expect(properties[:items][:items]).to include(
      type: "object",
      properties: {
        name: {type: "string"},
        value: {type: "integer"}
      },
      required: %i[name value],
      additionalProperties: false
    )
  end

  it "supports arrays with references to defined schemas" do
    schema_class.define :product do
      string :name
      number :price
    end

    schema_class.array :products, of: :product

    properties = schema_class.properties
    expect(properties[:products]).to eq({
      type: "array",
      items: {"$ref" => "#/$defs/product"}
    })
  end
end
