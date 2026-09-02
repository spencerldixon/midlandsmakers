module FullTextSearch
  extend ActiveSupport::Concern

  included do
    class_attribute :full_text_search_columns,
                    :full_text_search_table_name,
                    instance_writer: false
  end

  class_methods do
    def full_text_search_on(*columns, table_name: nil)
      columns = columns.flatten.map(&:to_s)

      if columns.empty?
        raise ArgumentError, "at least one searchable column is required"
      end

      self.full_text_search_columns = columns.freeze
      self.full_text_search_table_name = (table_name || "#{self.table_name}_fts").to_s
    end

    def full_text_search(query)
      return all if query.blank?

      ensure_full_text_search_configured!
      ensure_sqlite_adapter!
      ensure_full_text_search_columns_exist!

      match_query = sqlite_fts_query(query)
      return none if match_query.blank?

      fts_table = connection.quote_table_name(full_text_search_table_name)
      primary_key_column = connection.quote_column_name(primary_key)

      joins("INNER JOIN #{fts_table} ON #{fts_table}.rowid = #{quoted_table_name}.#{primary_key_column}")
        .where("#{fts_table} MATCH ?", match_query)
        .order(Arel.sql("bm25(#{fts_table})"))
    end

    private

    def ensure_full_text_search_configured!
      return if full_text_search_columns.present? && full_text_search_table_name.present?

      raise ArgumentError, "configure full text search with full_text_search_on first"
    end

    def ensure_sqlite_adapter!
      return if connection.adapter_name.casecmp?("SQLite")

      raise NotImplementedError, "FullTextSearch only supports SQLite"
    end

    def ensure_full_text_search_columns_exist!
      unknown_columns = full_text_search_columns - column_names
      return if unknown_columns.empty?

      raise ArgumentError, "unknown searchable columns: #{unknown_columns.join(', ')}"
    end

    def sqlite_fts_query(query)
      query.to_s.scan(/[[:alnum:]]+/).map { |term| %("#{term}"*) }.join(" AND ")
    end
  end
end
