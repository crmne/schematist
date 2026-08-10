# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "core keywords" do
  let(:schema_class) { Class.new(described_class) }

  it "supports root schema core keywords" do
    schema_class.id "https://example.com/schemas/person"
    schema_class.anchor "person"
    schema_class.comment "Internal note"
    schema_class.dynamic_anchor "node"
    schema_class.dynamic_ref "#node"
    schema_class.vocabulary "https://json-schema.org/draft/2020-12/vocab/core" => true

    schema = schema_class.new.to_json_schema[:schema]

    expect(schema).to include(
      "$id" => "https://example.com/schemas/person",
      "$anchor" => "person",
      "$comment" => "Internal note",
      "$dynamicAnchor" => "node",
      "$dynamicRef" => "#node",
      "$vocabulary" => {"https://json-schema.org/draft/2020-12/vocab/core" => true}
    )
  end

  it "reads back core keywords" do
    schema_class.id "https://example.com/schemas/person"

    expect(schema_class.id).to eq("https://example.com/schemas/person")
  end

  it "supports core keywords inside definitions" do
    schema_class.define :address do
      anchor "address"
      comment "Reusable address schema"

      string :street
    end

    definition = schema_class.definitions[:address]

    expect(definition["$anchor"]).to eq("address")
    expect(definition["$comment"]).to eq("Reusable address schema")
    expect(definition[:properties][:street]).to eq({type: "string"})
  end

  it "supports core keywords inside inline object schemas" do
    schema_class.object :node do
      dynamic_anchor "node"

      string :name
    end

    expect(schema_class.properties[:node]["$dynamicAnchor"]).to eq("node")
  end

  it "supports core keywords inside composition blocks" do
    schema_class.any_of :value do
      comment "Either shape is accepted"

      string
      integer
    end

    expect(schema_class.properties[:value]["$comment"]).to eq("Either shape is accepted")
  end

  it "supports core keywords on embedded schema classes" do
    address_schema = Class.new(described_class) do
      anchor "address"

      string :street
    end

    schema_class.object :address, of: address_schema

    expect(schema_class.properties[:address]["$anchor"]).to eq("address")
  end
end
