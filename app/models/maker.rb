class Maker < ApplicationRecord
  include FullTextSearch

  # There's no "category" field on the model any more — makers are tagged
  # directly (see the tag_list picker on the form). This is only kept as a
  # pure string->tags converter for db/seeds/makers.rb, which still imports
  # the original Wix data's free-text "category" per maker.
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

  acts_as_taggable_on :tags
  full_text_search_on :name, :description

  # unpublished: default for a new listing, and where "Unpublish" always
  #   sends it back to — never needs approval to get here.
  # pending_approval: the owner asked to go live; not shown on the public
  #   directory yet.
  # published: an admin approved it — the only status shown at root_path.
  enum :status, { unpublished: 0, pending_approval: 1, published: 2 }, default: :unpublished

  # The real display image, downloaded from image_url and stored on disk
  # (or S3 in production) by db/seeds/makers.rb, rather than hot-linking the
  # original site's image on every page view. Admin-created makers instead
  # upload here directly, so image_url is optional (see below).
  has_one_attached :image

  # The one listing a signed-in user can create and manage themselves (see
  # MakersController). Optional: the original 51 seeded makers have no
  # linked account, and an admin can still create/manage one without
  # assigning it to anyone.
  belongs_to :user, optional: true

  # image_url/source_url were only ever populated by the original Wix-scrape
  # seed import (image_url is the source photo to download from; source_url
  # is the original directory listing page) — makers created through the
  # app itself have neither.
  validates :name, :description, presence: true
  validates :name, uniqueness: { case_sensitive: false }
  validates :user_id, uniqueness: true, allow_nil: true

  def self.category_tags_for(category)
    CATEGORY_TAG_RULES.filter_map { |tag, pattern| tag if category.match?(pattern) }
                      .presence || [ category ]
  end

  def profile_url
    website_url.presence || instagram_url.presence || source_url.presence
  end
end
