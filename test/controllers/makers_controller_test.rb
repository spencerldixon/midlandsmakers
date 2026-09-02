require "test_helper"

class MakersControllerTest < ActionDispatch::IntegrationTest
  setup do
    Maker.delete_all
    User.delete_all

    @admin = create_user(email: "admin@example.com", admin: true)
    @owner = create_user(email: "owner@example.com")
    @other = create_user(email: "other@example.com")
    @owned_maker = Maker.create!(maker_attributes(name: "Owner's Studio", user: @owner))
  end

  test "requires sign in" do
    get makers_url
    assert_redirected_to new_user_session_url
  end

  test "a signed-in user only sees their own maker in the index" do
    sign_in @owner

    get makers_url

    assert_response :success
    assert_select "td", text: "Owner's Studio"
  end

  test "is marked noindex, unlike the public directory" do
    sign_in @owner

    get makers_url

    assert_select "meta[name=robots][content='noindex, nofollow']"
  end

  test "an admin sees every maker in the index" do
    Maker.create!(maker_attributes(name: "Someone Else", user: @other))
    sign_in @admin

    get makers_url

    assert_response :success
    assert_select "td", text: "Owner's Studio"
    assert_select "td", text: "Someone Else"
  end

  test "a signed-in user can create their own maker but not a second one" do
    sign_in @other

    assert_difference("Maker.count", 1) do
      post makers_url, params: { maker: maker_attributes(name: "Other's Shop").except(:user) }
    end
    assert_equal @other, Maker.find_by(name: "Other's Shop").user

    # already has one now — new/create should redirect to editing it, not
    # attempt (and fail on the unique index) to create a second
    get new_maker_url
    assert_redirected_to edit_maker_url(@other.maker)
  end

  test "a user cannot edit or destroy someone else's maker" do
    sign_in @other

    get edit_maker_url(@owned_maker)
    assert_redirected_to root_url

    assert_no_difference("Maker.count") do
      delete maker_url(@owned_maker)
    end
  end

  test "a user cannot assign a maker to another account" do
    sign_in @owner

    patch maker_url(@owned_maker), params: { maker: { user_id: @other.id } }

    assert_equal @owner, @owned_maker.reload.user
  end

  test "publishing always goes to pending_approval, never straight to published" do
    sign_in @owner

    patch publish_maker_url(@owned_maker)

    assert_redirected_to makers_url
    assert @owned_maker.reload.pending_approval?
  end

  test "unpublishing needs no approval" do
    @owned_maker.update!(status: :published)
    sign_in @owner

    patch unpublish_maker_url(@owned_maker)

    assert @owned_maker.reload.unpublished?
  end

  test "only an admin can approve a pending maker" do
    @owned_maker.update!(status: :pending_approval)
    sign_in @owner

    patch approve_maker_url(@owned_maker)

    assert_redirected_to root_url
    assert @owned_maker.reload.pending_approval?
  end

  test "an admin approving a pending maker publishes it" do
    @owned_maker.update!(status: :pending_approval)
    sign_in @admin

    patch approve_maker_url(@owned_maker)

    assert_redirected_to makers_url
    assert @owned_maker.reload.published?
  end

  private

  def create_user(email:, admin: false)
    User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123",
      terms_and_conditions: true,
      admin: admin,
      confirmed_at: Time.current
    )
  end

  def maker_attributes(name:, user: nil)
    {
      name: name,
      description: "Independent maker from the Midlands",
      user: user
    }
  end
end
