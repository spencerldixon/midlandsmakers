require "test_helper"

class DirectoryControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActsAsTaggableOn::Tagging.delete_all
    ActsAsTaggableOn::Tag.delete_all
    Maker.delete_all
    create_maker(
      name: "Clay Studio",
      category: "Ceramics",
      description: "Independent ceramic studio in the Midlands",
      website_url: "https://clay.example.com",
      instagram_url: "https://instagram.com/claystudio"
    )
    create_maker(name: "Silver Works", category: "Jewellery")
  end

  test "shows the public maker directory" do
    get root_url

    assert_response :success
    assert_select "form[role=search][data-controller=maker-search][data-turbo-frame=makers_results]"
    assert_select "turbo-frame#makers_results"
    assert_select "article", count: 2
    assert_select "h3", text: "Clay Studio"
    assert_select "h3", text: "Silver Works"
    assert_select "label", text: /Ceramics/
    assert_select "span", text: "Ceramics"
    assert_select "a[aria-label='Visit Clay Studio website'][href='https://clay.example.com']"
    assert_select "a[aria-label='Follow Clay Studio on Instagram'][href='https://instagram.com/claystudio']"
  end

  test "is indexable and carries SEO/social metadata" do
    get root_url

    assert_select "meta[name=robots]", count: 0
    assert_select "link[rel=canonical][href=?]", root_url
    assert_select "meta[property='og:image']"
    assert_select "meta[name='twitter:card'][content='summary_large_image']"
  end

  test "filters by one or more category tags" do
    create_maker(name: "Clay Jewels", category: "Ceramic jewellery")

    get root_url(tags: [ "Ceramics", "Jewellery" ])

    assert_response :success
    assert_select "input[name='tags[]'][value='Ceramics'][checked]"
    assert_select "input[name='tags[]'][value='Jewellery'][checked]"
    assert_select "article", count: 1
    assert_select "h3", text: "Clay Jewels"
  end

  test "filters cards with full text search" do
    get root_url(q: "ceram")

    assert_response :success
    assert_select "input[name=q][value=ceram]"
    assert_select "article", count: 1
    assert_select "h3", text: "Clay Studio"
    assert_select "h3", text: "Silver Works", count: 0
  end

  test "uses the Basecoat empty state when no makers match" do
    get root_url(q: "nothingmatches")

    assert_response :success
    assert_select ".empty" do
      assert_select "figure svg"
      assert_select "h3", text: "No makers found"
      assert_select "a.btn[href='#{root_path}']", text: "Show every maker"
    end
  end

  test "hides unpublished and pending-approval makers from the public directory" do
    create_maker(name: "Draft Studio", category: "Ceramics", status: :unpublished)
    create_maker(name: "Awaiting Review", category: "Ceramics", status: :pending_approval)

    get root_url

    assert_response :success
    assert_select "h3", text: "Draft Studio", count: 0
    assert_select "h3", text: "Awaiting Review", count: 0
  end

  private

  # category isn't a real column (see Maker) — it's only a convenient way for
  # these tests to say "give this maker the Ceramics/Jewellery/etc. tag" via
  # the same CATEGORY_TAG_RULES the original seed import used.
  def create_maker(name:, category:, description: "Independent maker from the Midlands", website_url: nil, instagram_url: nil, status: :published)
    maker = Maker.create!(
      name: name,
      description: description,
      image_url: "https://example.com/image.jpg",
      website_url: website_url,
      instagram_url: instagram_url,
      source_url: "https://example.com/directory",
      status: status
    )
    maker.tag_list = Maker.category_tags_for(category)
    maker.save!
    maker
  end
end
