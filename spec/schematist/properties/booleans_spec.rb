# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "boolean properties" do
  let(:schema_class) { Class.new(described_class) }

  it "supports boolean type with description" do
    schema_class.boolean :enabled, description: "Enabled field"

    properties = schema_class.properties
    expect(properties[:enabled]).to eq({type: "boolean", description: "Enabled field"})
  end

  it "supports boolean const values" do
    schema_class.boolean :enabled, const: false

    properties = schema_class.properties
    expect(properties[:enabled]).to eq({type: "boolean", const: false})
  end

  it "supports boolean enum values" do
    schema_class.boolean :enabled, enum: [true]

    expect(schema_class.properties[:enabled]).to eq({type: "boolean", enum: [true]})
  end
end
