class RemoveCategoryFromMakers < ActiveRecord::Migration[8.1]
  def up
    # category is one of the 3 columns the makers_fts5 virtual table and its
    # sync triggers reference by name (see CreateMakers) — has to be dropped
    # and rebuilt without it, not just the real column removed.
    execute "DROP TRIGGER IF EXISTS makers_fts_after_update"
    execute "DROP TRIGGER IF EXISTS makers_fts_after_delete"
    execute "DROP TRIGGER IF EXISTS makers_fts_after_insert"
    drop_virtual_table :makers_fts, :fts5, []

    remove_column :makers, :category, :string

    create_virtual_table :makers_fts, :fts5, [
      "name",
      "description",
      "content='makers'",
      "content_rowid='id'",
      "tokenize='unicode61 remove_diacritics 2'"
    ]

    execute <<~SQL
      CREATE TRIGGER makers_fts_after_insert AFTER INSERT ON makers BEGIN
        INSERT INTO makers_fts(rowid, name, description)
        VALUES (new.id, new.name, new.description);
      END;
    SQL

    execute <<~SQL
      CREATE TRIGGER makers_fts_after_delete AFTER DELETE ON makers BEGIN
        INSERT INTO makers_fts(makers_fts, rowid, name, description)
        VALUES ('delete', old.id, old.name, old.description);
      END;
    SQL

    execute <<~SQL
      CREATE TRIGGER makers_fts_after_update AFTER UPDATE ON makers BEGIN
        INSERT INTO makers_fts(makers_fts, rowid, name, description)
        VALUES ('delete', old.id, old.name, old.description);
        INSERT INTO makers_fts(rowid, name, description)
        VALUES (new.id, new.name, new.description);
      END;
    SQL

    execute "INSERT INTO makers_fts(makers_fts) VALUES ('rebuild')"
  end

  def down
    execute "DROP TRIGGER IF EXISTS makers_fts_after_update"
    execute "DROP TRIGGER IF EXISTS makers_fts_after_delete"
    execute "DROP TRIGGER IF EXISTS makers_fts_after_insert"
    drop_virtual_table :makers_fts, :fts5, []

    add_column :makers, :category, :string

    create_virtual_table :makers_fts, :fts5, [
      "name",
      "category",
      "description",
      "content='makers'",
      "content_rowid='id'",
      "tokenize='unicode61 remove_diacritics 2'"
    ]

    execute <<~SQL
      CREATE TRIGGER makers_fts_after_insert AFTER INSERT ON makers BEGIN
        INSERT INTO makers_fts(rowid, name, category, description)
        VALUES (new.id, new.name, new.category, new.description);
      END;
    SQL

    execute <<~SQL
      CREATE TRIGGER makers_fts_after_delete AFTER DELETE ON makers BEGIN
        INSERT INTO makers_fts(makers_fts, rowid, name, category, description)
        VALUES ('delete', old.id, old.name, old.category, old.description);
      END;
    SQL

    execute <<~SQL
      CREATE TRIGGER makers_fts_after_update AFTER UPDATE ON makers BEGIN
        INSERT INTO makers_fts(makers_fts, rowid, name, category, description)
        VALUES ('delete', old.id, old.name, old.category, old.description);
        INSERT INTO makers_fts(rowid, name, category, description)
        VALUES (new.id, new.name, new.category, new.description);
      END;
    SQL

    execute "INSERT INTO makers_fts(makers_fts) VALUES ('rebuild')"
  end
end
