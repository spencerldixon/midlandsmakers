class CreateActsAsTaggableOnTables < ActiveRecord::Migration[8.1]
  CATEGORY_TAG_RULES = {
    "Illustration" => /illustrat/i,
    "Jewellery" => /jewell/i,
    "Ceramics" => /ceramic|pottery|stoneware/i,
    "Homeware" => /homeware/i,
    "Fashion" => /fashion|clothing|apparel|lingerie/i,
    "Accessories" => /accessor|brooch|pins/i,
    "Food & Drink" => /bakery|baked goods/i,
    "Candles & Fragrance" => /candle|fragrance/i,
    "Textiles" => /textile|embroidery|sewing|plush/i,
    "Print & Lettering" => /print|letterpress|cards|sign painting/i,
    "Floristry" => /florist/i,
    "Wellness" => /wellness|soap/i,
    "Workshops" => /workshop/i,
    "Sustainable" => /sustainable|reworked/i,
    "Design" => /design/i
  }.freeze

  def up
    create_table :tags do |t|
      t.string :name, null: false
      t.integer :taggings_count, default: 0, null: false
      t.timestamps
    end
    add_index :tags, :name, unique: true

    create_table :taggings do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :taggable, polymorphic: true, null: false
      t.references :tagger, polymorphic: true
      t.string :context, limit: 128, null: false
      t.datetime :created_at, null: false
    end

    add_index :taggings,
              %i[tag_id taggable_id taggable_type context tagger_id tagger_type],
              unique: true,
              name: "taggings_idx"
    add_index :taggings, %i[taggable_id taggable_type context], name: "taggings_taggable_context_idx"
    add_index :taggings, %i[taggable_id taggable_type tagger_id context], name: "taggings_idy"
    add_index :taggings, :taggable_id
    add_index :taggings, :taggable_type
    add_index :taggings, :tagger_id
    add_index :taggings, :context

    backfill_maker_tags
  end

  def down
    drop_table :taggings
    drop_table :tags
  end

  private

  def backfill_maker_tags
    now = connection.quote(Time.current)

    connection.select_rows("SELECT id, category FROM makers").each do |maker_id, category|
      category_tags_for(category).each do |tag_name|
        quoted_name = connection.quote(tag_name)
        tag_id = connection.select_value("SELECT id FROM tags WHERE name = #{quoted_name}")

        unless tag_id
          execute <<~SQL.squish
            INSERT INTO tags (name, taggings_count, created_at, updated_at)
            VALUES (#{quoted_name}, 0, #{now}, #{now})
          SQL
          tag_id = connection.select_value("SELECT id FROM tags WHERE name = #{quoted_name}")
        end

        execute <<~SQL.squish
          INSERT INTO taggings (tag_id, taggable_type, taggable_id, context, created_at)
          VALUES (#{tag_id}, 'Maker', #{maker_id.to_i}, 'tags', #{now})
        SQL
      end
    end

    execute <<~SQL.squish
      UPDATE tags
      SET taggings_count = (
        SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id
      )
    SQL
  end

  def category_tags_for(category)
    CATEGORY_TAG_RULES.filter_map { |tag, pattern| tag if category.match?(pattern) }
                      .presence || [ category ]
  end
end
