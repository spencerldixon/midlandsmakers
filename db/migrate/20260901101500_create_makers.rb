class CreateMakers < ActiveRecord::Migration[8.1]
  def up
    create_table :makers do |t|
      t.string :name, null: false
      t.string :category, null: false
      t.text :description, null: false
      t.string :image_url, null: false
      t.string :website_url
      t.string :instagram_url
      t.string :source_url, null: false

      t.timestamps
    end

    add_index :makers, :name, unique: true
    add_index :makers, :category

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

  def down
    execute "DROP TRIGGER IF EXISTS makers_fts_after_update"
    execute "DROP TRIGGER IF EXISTS makers_fts_after_delete"
    execute "DROP TRIGGER IF EXISTS makers_fts_after_insert"
    drop_virtual_table :makers_fts, :fts5, []
    drop_table :makers
  end
end
