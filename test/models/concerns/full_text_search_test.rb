require "test_helper"

class FullTextSearchTest < Minitest::Test
  class SearchDocument < ApplicationRecord
    self.table_name = "full_text_search_test_documents"

    include FullTextSearch
    full_text_search_on :title, :body
  end

  def setup
    connection.execute(<<~SQL)
      CREATE TABLE full_text_search_test_documents (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL
      )
    SQL
    connection.execute(<<~SQL)
      CREATE VIRTUAL TABLE full_text_search_test_documents_fts USING fts5(
        title,
        body,
        content='full_text_search_test_documents',
        content_rowid='id'
      )
    SQL
    connection.execute(<<~SQL)
      CREATE TRIGGER full_text_search_test_documents_after_insert AFTER INSERT ON full_text_search_test_documents BEGIN
        INSERT INTO full_text_search_test_documents_fts(rowid, title, body)
        VALUES (new.id, new.title, new.body);
      END
    SQL
    connection.execute(<<~SQL)
      CREATE TRIGGER full_text_search_test_documents_after_delete AFTER DELETE ON full_text_search_test_documents BEGIN
        INSERT INTO full_text_search_test_documents_fts(full_text_search_test_documents_fts, rowid, title, body)
        VALUES ('delete', old.id, old.title, old.body);
      END
    SQL
    connection.execute(<<~SQL)
      CREATE TRIGGER full_text_search_test_documents_after_update AFTER UPDATE ON full_text_search_test_documents BEGIN
        INSERT INTO full_text_search_test_documents_fts(full_text_search_test_documents_fts, rowid, title, body)
        VALUES ('delete', old.id, old.title, old.body);
        INSERT INTO full_text_search_test_documents_fts(rowid, title, body)
        VALUES (new.id, new.title, new.body);
      END
    SQL
  end

  def teardown
    connection.execute("DROP TABLE IF EXISTS full_text_search_test_documents_fts")
    connection.execute("DROP TABLE IF EXISTS full_text_search_test_documents")
  end

  def test_searches_across_configured_columns_with_prefix_matching
    matching_title = SearchDocument.create!(title: "Birmingham ceramics", body: "A studio profile")
    matching_body = SearchDocument.create!(title: "Workshop", body: "Handmade ceramic tableware")
    SearchDocument.create!(title: "Metalwork", body: "Forged steel")

    assert_equal [ matching_title.id, matching_body.id ].sort,
                 SearchDocument.full_text_search("ceram").pluck(:id).sort
  end

  def test_requires_every_search_term
    matching = SearchDocument.create!(title: "Birmingham ceramics", body: "Independent maker")
    SearchDocument.create!(title: "Birmingham metalwork", body: "Independent maker")

    assert_equal [ matching.id ], SearchDocument.full_text_search("Birmingham ceramic").pluck(:id)
  end

  def test_handles_fts_punctuation_as_plain_user_input
    matching = SearchDocument.create!(title: "Maker's studio", body: "Birmingham")

    assert_equal [ matching.id ], SearchDocument.full_text_search(%(maker's "studio")).pluck(:id)
    assert_empty SearchDocument.full_text_search("***")
  end

  def test_returns_all_records_for_a_blank_query
    documents = [
      SearchDocument.create!(title: "Ceramics", body: "Clay"),
      SearchDocument.create!(title: "Metalwork", body: "Steel")
    ]

    assert_equal documents.map(&:id).sort, SearchDocument.full_text_search(" ").pluck(:id).sort
  end

  private

  def connection
    SearchDocument.connection
  end
end
