# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingUniqueIndexesTest < Minitest::Test
  def test_missing_unique_index
    create_table(:users) do |t|
      t.string :email
      t.index :email
    end.create_model do
      validates :email, uniqueness: true
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(email) - validating uniqueness in the model without an index can lead to duplicates
    OUTPUT
  end

  def test_present_unique_index
    create_table(:users) do |t|
      t.string :email
      t.index :email, unique: true
    end.create_model do
      validates :email, uniqueness: true
    end

    refute_problems
  end

  def test_missing_unique_index_with_scope
    create_table(:users) do |t|
      t.string :email
      t.integer :company_id
      t.integer :department_id
      t.index [:company_id, :department_id, :email]
    end.create_model do
      validates :email, uniqueness: { scope: [:company_id, :department_id] }
    end

    assert_problems(<<~OUTPUT)
      add a unique index on users(company_id, department_id, email) - validating uniqueness in the model without an index can lead to duplicates
    OUTPUT
  end

  def test_present_unique_index_with_scope
    create_table(:users) do |t|
      t.string :email
      t.integer :company_id
      t.integer :department_id
      t.index [:company_id, :department_id, :email], unique: true
    end.create_model do
      validates :email, uniqueness: { scope: [:company_id, :department_id] }
    end

    refute_problems
  end

  def test_column_order_is_ignored
    create_table(:users) do |t|
      t.string :email
      t.integer :organization_id

      t.index [:email, :organization_id], unique: true
    end.create_model do
      validates :email, uniqueness: { scope: :organization_id }
    end

    refute_problems
  end

  def test_conditions_is_skipped
    assert_skipped(conditions: -> { where.not(email: nil) })
  end

  def test_case_insensitive_is_skipped
    assert_skipped(case_sensitive: false)
  end

  def test_if_is_skipped
    assert_skipped(if: ->(_model) { true })
  end

  def test_unless_is_skipped
    assert_skipped(unless: ->(_model) { true })
  end

  def test_skips_validator_without_attributes
    create_table(:users) do |t|
      t.string :email
      t.index :email
    end.create_model do
      validates_with DummyValidator
    end

    refute_problems
  end

  def test_config_ignore_models
    create_table(:users) do |t|
      t.string :email
    end.create_model do
      validates :email, uniqueness: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_unique_indexes,
          ignore_models: ["ModelFactory::Models::User"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    create_table(:users) do |t|
      t.string :email
    end.create_model do
      validates :email, uniqueness: true
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["ModelFactory::Models::User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    create_table(:users) do |t|
      t.string :email
      t.integer :role
    end.create_model do
      validates :email, :role, uniqueness: { scope: :organization_id }
    end

    config_file(<<-CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_unique_indexes,
          ignore_columns: ["ModelFactory::Models::User(organization_id, email, role)"]
      end
    CONFIG

    refute_problems
  end

  class DummyValidator < ActiveModel::Validator
    def validate(record)
    end
  end

  private

  def assert_skipped(options)
    create_table(:users) do |t|
      t.string :email
    end.create_model do
      validates :email, uniqueness: options
    end

    refute_problems
  end
end
