# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "validation" do
  include SchemaBuilders

  let(:schema_class) { build_schema_class }

  def define_user(schema)
    schema.define :user do
      string :name
    end
  end

  describe "circular reference detection" do
    it "detects direct circular references" do
      define_user(schema_class)
      schema_class.definitions[:user][:properties][:self_ref] = schema_class.reference(:user)

      expect(schema_class.valid?).to be false
      expect { schema_class.validate! }.to raise_error(
        Schematist::ValidationError,
        /Circular reference detected involving 'user'/
      )
    end

    it "detects indirect circular references" do
      define_user(schema_class)

      schema_class.define :profile do
        string :bio
      end

      schema_class.definitions[:user][:properties][:profile] = schema_class.reference(:profile)
      schema_class.definitions[:profile][:properties][:owner] = schema_class.reference(:user)

      expect(schema_class.valid?).to be false
      expect { schema_class.validate! }.to raise_error(
        Schematist::ValidationError,
        /Circular reference detected involving/
      )
    end
  end

  describe "validation guards for JSON generation" do
    it "prevents JSON generation for schemas with circular references" do
      define_user(schema_class)
      schema_class.definitions[:user][:properties][:self_ref] = schema_class.reference(:user)

      instance = schema_class.new
      expect { instance.to_json_schema }.to raise_error(Schematist::ValidationError)
      expect { instance.to_json }.to raise_error(Schematist::ValidationError)
    end
  end
end
