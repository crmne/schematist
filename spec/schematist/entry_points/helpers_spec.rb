# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "helpers module approach" do
  include SchemaBuilders

  describe "schema attributes" do
    it "derives schema names from parameters and defaults" do
      named_schema = build_helper_schema("ProvidedName") { string :title }
      expect(named_schema.to_json_schema["title"]).to eq("ProvidedName")

      default_schema = build_helper_schema { string :title }
      expect(default_schema.to_json_schema["title"]).to eq("Schema")
    end

    it "honours description precedence" do
      default_output = build_helper_schema("TestSchema") { string :title }.to_json_schema
      expect(default_output["description"]).to be_nil

      block_description = build_helper_schema("TestSchema") do
        description "Block description"
        string :title
      end.to_json_schema
      expect(block_description["description"]).to eq("Block description")

      parameter_override = build_helper_schema(
        "TestSchema",
        description: "Parameter description"
      ) do
        description "Block description"
        string :title
      end.to_json_schema
      expect(parameter_override["description"]).to eq("Parameter description")
    end

    it "controls additional properties" do
      default_output = build_helper_schema { string :title }.to_json_schema
      expect(default_output["additionalProperties"]).to eq(false)

      configured_output = build_helper_schema do
        additional_properties true
        string :title
      end.to_json_schema

      expect(configured_output["additionalProperties"]).to eq(true)
    end

    it "renders structured JSON schema" do
      json_output = build_helper_schema(
        "HelperConfiguredSchema",
        description: "Helper test description"
      ) do
        additional_properties false
        string :title
        integer :count, required: false
      end.to_json_schema

      expect(json_output).to include(
        "title" => "HelperConfiguredSchema",
        "description" => "Helper test description",
        "type" => "object",
        "properties" => {
          "title" => {"type" => "string"},
          "count" => {"type" => "integer"}
        },
        "required" => ["title"],
        "additionalProperties" => false
      )
    end
  end

  describe "comprehensive scenario" do
    it "supports full-feature schemas" do
      json_output = build_helper_schema(
        "HelperSchema",
        description: "Comprehensive helper schema"
      ) do
        additional_properties true

        string :name, description: "Name field"
        integer :count
        boolean :active, required: false

        object :config do
          string :setting
        end

        array :tags, of: :string

        any_of :status do
          string
          null
        end
      end.to_json_schema

      expect(json_output["title"]).to eq("HelperSchema")
      expect(json_output["description"]).to eq("Comprehensive helper schema")
      expect(json_output["additionalProperties"]).to eq(true)
      expect(json_output["properties"].keys).to contain_exactly(
        "name", "count", "active", "config", "tags", "status"
      )
      expect(json_output["required"]).to contain_exactly("name", "count", "config", "tags", "status")
    end
  end
end
