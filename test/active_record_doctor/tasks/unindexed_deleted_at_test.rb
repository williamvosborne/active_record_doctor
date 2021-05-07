class ActiveRecordDoctor::Tasks::UnindexedDeletedAtTest < Minitest::Test
  def test_indexed_deleted_at_is_not_reported
    create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :deleted_at
      t.index [:first_name, :last_name],
        name: 'index_profiles_on_first_name_and_last_name',
        where: 'deleted_at IS NULL'
    end

    assert_result([])
  end

  def test_unindexed_deleted_at_is_reported
    create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :deleted_at
      t.index [:first_name, :last_name],
        name: 'index_profiles_on_first_name_and_last_name'
    end

    assert_result(['index_profiles_on_first_name_and_last_name'])
  end

  def test_indexed_discarded_at_is_not_reported
    create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :discarded_at
      t.index [:first_name, :last_name],
        name: 'index_profiles_on_first_name_and_last_name',
        where: 'discarded_at IS NULL'
    end

    assert_result([])
  end

  def test_unindexed_discarded_at_is_reported
    create_table(:users) do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :discarded_at
      t.index [:first_name, :last_name],
        name: 'index_profiles_on_first_name_and_last_name'
    end

    assert_result(['index_profiles_on_first_name_and_last_name'])
  end
end
