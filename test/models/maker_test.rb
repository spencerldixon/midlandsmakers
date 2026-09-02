require "test_helper"

class MakerTest < ActiveSupport::TestCase
  setup do
    ActsAsTaggableOn::Tagging.delete_all
    ActsAsTaggableOn::Tag.delete_all
    Maker.delete_all
  end

  test "searches names and descriptions with prefixes" do
    ceramicist = create_maker(name: "Clay Studio", description: "Ceramic tableware made in Derby")
    jeweller = create_maker(name: "Silver Works", description: "Recycled silver from Leicester")

    assert_equal [ ceramicist ], Maker.full_text_search("ceram").to_a
    assert_equal [ jeweller ], Maker.full_text_search("Leic").to_a
  end

  test "keeps the search index synchronized after updates and deletes" do
    maker = create_maker(description: "Handmade candles")

    maker.update!(description: "Handmade natural soap")

    assert_empty Maker.full_text_search("candles")
    assert_equal [ maker ], Maker.full_text_search("soap").to_a

    maker.destroy!

    assert_empty Maker.full_text_search("soap")
  end

  test "prefers a website then Instagram for the profile link" do
    maker = create_maker(website_url: "https://example.com", instagram_url: "https://instagram.com/example")
    assert_equal "https://example.com", maker.profile_url

    maker.website_url = nil
    assert_equal "https://instagram.com/example", maker.profile_url
  end

  test "normalizes source categories into multiple useful tags" do
    assert_equal [ "Jewellery", "Ceramics", "Homeware" ], Maker.category_tags_for("Ceramic jewellery and homeware")
  end

  private

  def create_maker(attributes = {})
    defaults = {
      name: "Example Maker #{SecureRandom.hex(4)}",
      description: "Handmade textiles from Birmingham",
      image_url: "https://example.com/image.jpg",
      source_url: "https://example.com/directory"
    }

    Maker.create!(defaults.merge(attributes))
  end
end
