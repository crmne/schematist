# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "null properties" do
  let(:schema_class) { Class.new(described_class) }

  it "supports null type with description" do
    schema_class.null :placeholder, description: "Null field"

    properties = schema_class.properties
    expect(properties[:placeholder]).to eq({type: "null", description: "Null field"})
  end

  it "supports null const values" do
    schema_class.null :deleted_at, const: nil

    properties = schema_class.properties
    expect(properties[:deleted_at]).to eq({type: "null", const: nil})
  end
end
