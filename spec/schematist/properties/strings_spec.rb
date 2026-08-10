# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "string properties" do
  let(:schema_class) { Class.new(described_class) }

  it "supports string type with enum and description" do
    schema_class.string :status, enum: %w[active inactive], description: "Status field"

    properties = schema_class.properties
    expect(properties[:status]).to eq({
      type: "string",
      enum: %w[active inactive],
      description: "Status field"
    })
  end

  it "supports string const values" do
    schema_class.string :role, const: "admin"

    properties = schema_class.properties
    expect(properties[:role]).to eq({type: "string", const: "admin"})
  end

  it "supports string type with additional options" do
    schema_class.string :email, format: "email", min_length: 5, max_length: 100, pattern: "\\S+@\\S+", description: "Email field"

    properties = schema_class.properties
    expect(properties[:email]).to eq({
      type: "string",
      format: "email",
      minLength: 5,
      maxLength: 100,
      pattern: "\\S+@\\S+",
      description: "Email field"
    })
  end

  it "handles required vs optional string properties" do
    schema_class.string :required_field
    schema_class.string :optional_field, required: false

    expect(schema_class.required_properties).to include(:required_field)
    expect(schema_class.required_properties).not_to include(:optional_field)
  end
end
