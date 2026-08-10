# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "JSON Schema output" do
  let(:schema_class) do
    Class.new(described_class) do
      string :name
      integer :age, required: false
    end
  end

  describe "#to_json_schema" do
    it "returns a Draft 2020-12 document with string keys" do
      expect(schema_class.new("PersonSchema").to_json_schema).to eq({
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "title" => "PersonSchema",
        "type" => "object",
        "properties" => {
          "name" => {"type" => "string"},
          "age" => {"type" => "integer"}
        },
        "required" => ["name"],
        "additionalProperties" => false
      })
    end

    it "omits the provider-only strict key" do
      expect(schema_class.new.to_json_schema).not_to have_key("strict")
    end

    it "prefers an explicit title over the schema name" do
      schema_class.title "Person"

      expect(schema_class.new("PersonSchema").to_json_schema["title"]).to eq("Person")
    end

    it "prefers an instance description over the class description" do
      schema_class.description "Class description"

      document = schema_class.new("PersonSchema", description: "Instance description").to_json_schema

      expect(document["description"]).to eq("Instance description")
    end

    it "stringifies definitions and references" do
      schema_class.define :address do
        string :street
      end
      schema_class.object :home, of: :address

      document = schema_class.new.to_json_schema

      expect(document["properties"]["home"]).to eq({"$ref" => "#/$defs/address"})
      expect(document["$defs"]["address"]["required"]).to eq(["street"])
    end

    it "survives a JSON round trip unchanged" do
      document = schema_class.new("PersonSchema").to_json_schema

      expect(JSON.parse(JSON.generate(document))).to eq(document)
    end
  end

  describe "#to_json" do
    it "serializes the Draft 2020-12 document" do
      expect(JSON.parse(schema_class.new("PersonSchema").to_json)).to eq(schema_class.new("PersonSchema").to_json_schema)
    end
  end
end
