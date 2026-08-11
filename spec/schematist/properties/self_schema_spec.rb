# frozen_string_literal: true

require "spec_helper"

# A type with a name declares a property. Without a name it declares what the schema itself is,
# which is what lets a root or a definition be something other than an object.
RSpec.describe Schematist::Schema, "schemas that are not objects" do
  let(:schema_class) { Class.new(described_class) }

  describe "at the root" do
    it "makes the root an array" do
      schema_class.array of: :string, unique: true

      expect(schema_class.new("Tags").to_json_schema).to eq({
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "title" => "Tags",
        "type" => "array",
        "items" => {"type" => "string"},
        "uniqueItems" => true
      })
    end

    it "makes the root a choice" do
      schema_class.one_of do
        string
        integer
      end

      expect(schema_class.new("Id").to_json_schema["oneOf"]).to eq([{"type" => "string"}, {"type" => "integer"}])
    end

    it "makes the root a reference" do
      schema_class.raw({"$ref" => "https://example.com/person.json"})

      expect(schema_class.new.to_json_schema["$ref"]).to eq("https://example.com/person.json")
    end

    it "makes the root a string" do
      schema_class.string pattern: "^x"

      expect(schema_class.new.to_json_schema).to include("type" => "string", "pattern" => "^x")
    end

    it "still defaults to an object built from properties" do
      schema_class.string :name

      expect(schema_class.new.to_json_schema).to include("type" => "object", "required" => ["name"])
    end

    it "supports object keywords at the root" do
      schema_class.string :name
      schema_class.min_properties 1
      schema_class.max_properties 10
      schema_class.unevaluated_properties false

      expect(schema_class.new.to_json_schema).to include(
        "minProperties" => 1,
        "maxProperties" => 10,
        "unevaluatedProperties" => false
      )
    end
  end

  describe "in a definition" do
    it "defines a string" do
      schema_class.define(:status) { string enum: %w[draft sent] }

      expect(schema_class.definitions[:status]).to eq({type: "string", enum: %w[draft sent]})
    end

    it "defines an array" do
      schema_class.define(:tags) { array of: :string }

      expect(schema_class.definitions[:tags]).to eq({type: "array", items: {type: "string"}})
    end

    it "defines a union" do
      schema_class.define(:id) do
        one_of do
          string
          integer
        end
      end

      expect(schema_class.definitions[:id][:oneOf].length).to eq(2)
    end

    it "still defines an object from properties" do
      schema_class.define(:address) { string :street }

      expect(schema_class.definitions[:address]).to include(type: "object")
    end

    it "detects a cycle through a definition that is not an object" do
      schema_class.define(:node) do
        one_of do
          raw({"$ref" => "#/$defs/node"})
          string
        end
      end
      schema_class.object :root, of: :node

      expect { schema_class.new.to_json_schema }.to raise_error(Schematist::ValidationError, /node/)
    end
  end
end
