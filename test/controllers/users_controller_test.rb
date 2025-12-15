require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "show displays user profile" do
    get user_path(@user.username)
    assert_response :success
  end

  test "show displays user posts" do
    get user_path(@user.username)
    assert_response :success
  end

  test "show with non-existent user returns 404" do
    get user_path(username: "nonexistent")
    assert_response :not_found
  end

  test "show supports pagination" do
    get user_path(@user.username, page: 1)
    assert_response :success
  end

  test "show uses username as param" do
    get user_path(@user.username)
    assert_response :success
  end

  # Edit tests
  test "edit requires authentication" do
    get edit_user_path(@user.username)
    assert_redirected_to new_user_session_path
  end

  test "edit own profile displays form" do
    sign_in @user
    get edit_user_path(@user.username)
    assert_response :success
    assert_select "form"
    assert_select "input[name='user[display_name]']"
    assert_select "textarea[name='user[bio]']"
    assert_select "input[name='user[website]']"
  end

  test "cannot edit other users profile" do
    sign_in @user
    other_user = users(:bob)
    get edit_user_path(other_user.username)
    assert_redirected_to user_path(other_user.username)
    assert_equal "You can only edit your own profile", flash[:alert]
  end

  # Update tests
  test "update requires authentication" do
    patch user_path(@user.username), params: { user: { display_name: "New Name" } }
    assert_redirected_to new_user_session_path
  end

  test "update own profile" do
    sign_in @user
    patch user_path(@user.username), params: {
      user: {
        display_name: "Alice Updated",
        bio: "New bio here",
        website: "https://newwebsite.com"
      }
    }

    assert_redirected_to user_path(@user.username)
    assert_equal "Profile updated successfully", flash[:notice]

    @user.reload
    assert_equal "Alice Updated", @user.display_name
    assert_equal "New bio here", @user.bio
    assert_equal "https://newwebsite.com", @user.website
  end

  test "update own profile with avatar" do
    sign_in @user
    file = fixture_file_upload("test_image.jpg", "image/jpeg")

    patch user_path(@user.username), params: {
      user: {
        display_name: "Alice Updated",
        avatar: file
      }
    }

    assert_redirected_to user_path(@user.username)
    assert_equal "Profile updated successfully", flash[:notice]

    @user.reload
    assert_equal "Alice Updated", @user.display_name
    assert @user.avatar.attached?
  end

  test "cannot update other users profile" do
    sign_in @user
    other_user = users(:bob)
    original_name = other_user.display_name

    patch user_path(other_user.username), params: {
      user: { display_name: "Hacked Name" }
    }

    assert_redirected_to user_path(other_user.username)
    assert_equal "You can only edit your own profile", flash[:alert]

    other_user.reload
    assert_equal original_name, other_user.display_name
  end

  test "update with invalid website url renders edit form" do
    sign_in @user
    patch user_path(@user.username), params: {
      user: { website: "not-a-valid-url" }
    }

    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "update with invalid avatar url renders edit form" do
    sign_in @user
    patch user_path(@user.username), params: {
      user: { avatar_url: "not-a-valid-url" }
    }

    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "update with valid urls succeeds" do
    sign_in @user
    patch user_path(@user.username), params: {
      user: {
        website: "https://example.com",
        avatar_url: "https://example.com/avatar.png"
      }
    }

    assert_redirected_to user_path(@user.username)
    @user.reload
    assert_equal "https://example.com", @user.website
    assert_equal "https://example.com/avatar.png", @user.avatar_url
  end

  test "update clears optional fields when blank" do
    @user.update!(bio: "Old bio", website: "https://old.com")
    sign_in @user

    patch user_path(@user.username), params: {
      user: { bio: "", website: "" }
    }

    assert_redirected_to user_path(@user.username)
    @user.reload
    assert_equal "", @user.bio
    assert_equal "", @user.website
  end

  test "show displays edit button for own profile" do
    sign_in @user
    get user_path(@user.username)
    assert_response :success
    assert_select "a[href='#{edit_user_path(@user.username)}']", text: "Edit Profile"
  end

  test "show does not display edit button for other profiles" do
    sign_in @user
    other_user = users(:bob)
    get user_path(other_user.username)
    assert_response :success
    assert_select "a[href='#{edit_user_path(other_user.username)}']", count: 0
  end
end
