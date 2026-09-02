CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "users" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "email" varchar DEFAULT '' NOT NULL, "encrypted_password" varchar DEFAULT '' NOT NULL, "reset_password_token" varchar, "reset_password_sent_at" datetime(6), "remember_created_at" datetime(6), "sign_in_count" integer DEFAULT 0 NOT NULL, "current_sign_in_at" datetime(6), "last_sign_in_at" datetime(6), "current_sign_in_ip" varchar, "last_sign_in_ip" varchar, "confirmation_token" varchar, "confirmed_at" datetime(6), "confirmation_sent_at" datetime(6), "unconfirmed_email" varchar, "failed_attempts" integer DEFAULT 0 NOT NULL, "unlock_token" varchar, "locked_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "admin" boolean DEFAULT FALSE /*application='Midlandsmakers'*/);
CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email") /*application='Midlandsmakers'*/;
CREATE UNIQUE INDEX "index_users_on_reset_password_token" ON "users" ("reset_password_token") /*application='Midlandsmakers'*/;
CREATE UNIQUE INDEX "index_users_on_confirmation_token" ON "users" ("confirmation_token") /*application='Midlandsmakers'*/;
CREATE UNIQUE INDEX "index_users_on_unlock_token" ON "users" ("unlock_token") /*application='Midlandsmakers'*/;
CREATE TABLE IF NOT EXISTS "tags" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "taggings_count" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_tags_on_name" ON "tags" ("name") /*application='Midlandsmakers'*/;
CREATE TABLE IF NOT EXISTS "taggings" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "tag_id" integer NOT NULL, "taggable_type" varchar NOT NULL, "taggable_id" integer NOT NULL, "tagger_type" varchar, "tagger_id" integer, "context" varchar(128) NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_9fcd2e236b"
FOREIGN KEY ("tag_id")
  REFERENCES "tags" ("id")
);
CREATE INDEX "index_taggings_on_tag_id" ON "taggings" ("tag_id") /*application='Midlandsmakers'*/;
CREATE INDEX "index_taggings_on_taggable" ON "taggings" ("taggable_type", "taggable_id") /*application='Midlandsmakers'*/;
CREATE INDEX "index_taggings_on_tagger" ON "taggings" ("tagger_type", "tagger_id") /*application='Midlandsmakers'*/;
CREATE UNIQUE INDEX "taggings_idx" ON "taggings" ("tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type") /*application='Midlandsmakers'*/;
CREATE INDEX "taggings_taggable_context_idx" ON "taggings" ("taggable_id", "taggable_type", "context") /*application='Midlandsmakers'*/;
CREATE INDEX "taggings_idy" ON "taggings" ("taggable_id", "taggable_type", "tagger_id", "context") /*application='Midlandsmakers'*/;
CREATE INDEX "index_taggings_on_taggable_id" ON "taggings" ("taggable_id") /*application='Midlandsmakers'*/;
CREATE INDEX "index_taggings_on_taggable_type" ON "taggings" ("taggable_type") /*application='Midlandsmakers'*/;
CREATE INDEX "index_taggings_on_tagger_id" ON "taggings" ("tagger_id") /*application='Midlandsmakers'*/;
CREATE INDEX "index_taggings_on_context" ON "taggings" ("context") /*application='Midlandsmakers'*/;
CREATE TABLE IF NOT EXISTS "active_storage_blobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "filename" varchar NOT NULL, "content_type" varchar, "metadata" text, "service_name" varchar NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key") /*application='Midlandsmakers'*/;
CREATE TABLE IF NOT EXISTS "active_storage_attachments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "record_type" varchar NOT NULL, "record_id" bigint NOT NULL, "blob_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id") /*application='Midlandsmakers'*/;
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id") /*application='Midlandsmakers'*/;
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest") /*application='Midlandsmakers'*/;
CREATE TABLE IF NOT EXISTS "makers" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "description" text NOT NULL, "image_url" varchar, "website_url" varchar, "instagram_url" varchar, "source_url" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "user_id" integer, "status" integer DEFAULT 0 NOT NULL, CONSTRAINT "fk_rails_f82b7c4b17"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE UNIQUE INDEX "index_makers_on_name" ON "makers" ("name") /*application='Midlandsmakers'*/;
CREATE UNIQUE INDEX "index_makers_on_user_id" ON "makers" ("user_id") /*application='Midlandsmakers'*/;
CREATE INDEX "index_makers_on_status" ON "makers" ("status") /*application='Midlandsmakers'*/;
CREATE VIRTUAL TABLE makers_fts USING fts5 (name, description, content='makers', content_rowid='id', tokenize='unicode61 remove_diacritics 2')
/* makers_fts(name,description) */;
CREATE TABLE IF NOT EXISTS 'makers_fts_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'makers_fts_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'makers_fts_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE IF NOT EXISTS 'makers_fts_config'(k PRIMARY KEY, v) WITHOUT ROWID;
CREATE TRIGGER makers_fts_after_insert AFTER INSERT ON makers BEGIN
  INSERT INTO makers_fts(rowid, name, description)
  VALUES (new.id, new.name, new.description);
END;
CREATE TRIGGER makers_fts_after_delete AFTER DELETE ON makers BEGIN
  INSERT INTO makers_fts(makers_fts, rowid, name, description)
  VALUES ('delete', old.id, old.name, old.description);
END;
CREATE TRIGGER makers_fts_after_update AFTER UPDATE ON makers BEGIN
  INSERT INTO makers_fts(makers_fts, rowid, name, description)
  VALUES ('delete', old.id, old.name, old.description);
  INSERT INTO makers_fts(rowid, name, description)
  VALUES (new.id, new.name, new.description);
END;
INSERT INTO "schema_migrations" (version) VALUES
('20260901154643'),
('20260901152758'),
('20260901141515'),
('20260901133458'),
('20260901120000'),
('20260901101500'),
('20260901085114'),
('20260901085113');

