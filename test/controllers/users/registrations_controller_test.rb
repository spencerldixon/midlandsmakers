require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "allows sign-up when registration is enabled" do
    with_registration_enabled(true) do
      get new_user_registration_url
      assert_response :success
    end
  end

  test "blocks sign-up when registration is disabled" do
    with_registration_enabled(false) do
      get new_user_registration_url
      assert_redirected_to new_user_session_url

      assert_no_difference("User.count") do
        post user_registration_url, params: {
          user: {
            email: "blocked@example.com",
            password: "password123",
            password_confirmation: "password123",
            terms_and_conditions: "1"
          }
        }
      end
    end
  end

  test "hides the sign-up link on the sign-in page when disabled" do
    with_registration_enabled(false) do
      get new_user_session_url
      assert_select "a[href='#{new_user_registration_path}']", count: 0
    end
  end

  private

  def with_registration_enabled(value)
    original = Rails.application.config.x.registration_enabled
    Rails.application.config.x.registration_enabled = value
    yield
  ensure
    Rails.application.config.x.registration_enabled = original
  end
end
