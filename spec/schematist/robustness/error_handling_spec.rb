# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "error handling" do
  include SchemaBuilders

  let(:schema_class) { build_schema_class }

  it "raises appropriate errors for invalid configurations" do
    expect {
      schema_class.array :items, of: 123
    }.to raise_error(Schematist::InvalidArrayTypeError, /Invalid array type: 123./)

    expect {
      schema_class.array :items, of: "invalid"
    }.to raise_error(Schematist::InvalidArrayTypeError, /Invalid array type: "invalid"./)
  end

  it "raises clear errors for invalid object types" do
    expect {
      schema_class.object :item, of: 123
    }.to raise_error(Schematist::InvalidObjectTypeError, /Invalid object type: 123.*Must be a symbol reference, a Schema class, or a Schema instance/)

    expect {
      schema_class.object :item, of: "invalid"
    }.to raise_error(Schematist::InvalidObjectTypeError, /Invalid object type: "invalid".*Must be a symbol reference, a Schema class, or a Schema instance/)

    expect {
      schema_class.object :item, of: String
    }.to raise_error(Schematist::InvalidObjectTypeError, /Invalid object type: String.*Class must inherit from Schematist::Schema/)
  end

  it "accepts anonymous schema classes with inline schemas" do
    anonymous_schema = build_schema_class do
      string :test_field
    end

    expect {
      schema_class.object :item, of: anonymous_schema
    }.not_to raise_error

    properties = schema_class.properties
    expect(properties[:item]).to eq({
      type: "object",
      properties: {
        test_field: {type: "string"}
      },
      required: [:test_field],
      additionalProperties: false
    })
  end

  it "accepts symbols as references (even if undefined)" do
    expect {
      schema_class.array :items, of: :undefined_reference
    }.not_to raise_error

    properties = schema_class.properties
    expect(properties[:items][:items]).to eq({"$ref" => "#/$defs/undefined_reference"})
  end
end
