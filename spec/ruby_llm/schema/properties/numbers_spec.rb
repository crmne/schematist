# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "numeric properties" do
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

  it "supports integer enum values" do
    schema_class.integer :level, enum: [0, 1, 2]

    properties = schema_class.properties
    expect(properties[:level]).to eq({type: "integer", enum: [0, 1, 2]})
  end
end
