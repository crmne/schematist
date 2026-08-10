# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "factory method (.create) approach" do
  include SchemaBuilders

  describe "schema attributes" do
    let(:base_schema) { build_factory_schema { string :title } }

    it "derives schema names from constants, instances, and defaults" do
      stub_const("NamedFactorySchema", build_factory_schema { string :title })
      expect(NamedFactorySchema.new.to_json_schema["title"]).to eq("NamedFactorySchema")

      expect(base_schema.new.to_json_schema["title"]).to eq("Schema")
      expect(base_schema.new("CustomName").to_json_schema["title"]).to eq("CustomName")
    end

    it "honours description precedence" do
      schema_with_description = build_factory_schema do
        description "Factory description"
        string :title
      end

      anonymous_output = base_schema.new.to_json_schema
      expect(anonymous_output["description"]).to be_nil

      class_level_output = schema_with_description.new.to_json_schema
      expect(class_level_output["description"]).to eq("Factory description")

      instance_override = schema_with_description.new("NamedSchema", description: "Instance description").to_json_schema
      expect(instance_override["description"]).to eq("Instance description")
    end

    it "controls additional properties" do
      default_output = base_schema.new.to_json_schema
      expect(default_output["additionalProperties"]).to eq(false)

      configured_schema = build_factory_schema do
        additional_properties true
        string :title
      end

      configured_output = configured_schema.new.to_json_schema
      expect(configured_output["additionalProperties"]).to eq(true)
    end

    it "renders structured JSON schema" do
      configured_schema = build_factory_schema do
        description "Factory test description"
        additional_properties false
        string :title
        integer :count, required: false
      end

      output = configured_schema.new("FactoryConfiguredSchema").to_json_schema

      expect(output).to include(
        "title" => "FactoryConfiguredSchema",
        "description" => "Factory test description",
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
    let(:schema_class) do
      build_factory_schema do
        description "Comprehensive factory schema"
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
      end
    end

    it "supports full-feature schemas" do
      json_output = schema_class.new("FactorySchema").to_json_schema

      expect(json_output["title"]).to eq("FactorySchema")
      expect(json_output["additionalProperties"]).to eq(true)
      expect(json_output["properties"].keys).to contain_exactly(
        "name", "count", "active", "config", "tags", "status"
      )
      expect(json_output["required"]).to contain_exactly("name", "count", "config", "tags", "status")
    end
  end
end
