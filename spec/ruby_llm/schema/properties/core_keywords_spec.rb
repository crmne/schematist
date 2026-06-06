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

  it "supports core keywords inside definitions" do
    schema_class.define :address do
      anchor "address"
      comment "Reusable address schema"

      string :street
    end

    definition = schema_class.definitions[:address]

    expect(definition["$anchor"]).to eq("address")
    expect(definition["$comment"]).to eq("Reusable address schema")
  end

  it "supports core keywords inside nested object schemas" do
    schema_class.object :node do
      dynamic_anchor "node"

      string :value
    end

    node_schema = schema_class.properties[:node]

    expect(node_schema["$dynamicAnchor"]).to eq("node")
    expect(node_schema[:properties][:value]).to eq({type: "string"})
  end

  it "supports core keywords on composition schemas" do
    schema_class.any_of :identifier do
      comment "Accepted identifier formats"

      string
      integer
    end

    identifier_schema = schema_class.properties[:identifier]

    expect(identifier_schema["$comment"]).to eq("Accepted identifier formats")
    expect(identifier_schema[:anyOf].map { |schema| schema[:type] }).to eq(%w[string integer])
  end
end
