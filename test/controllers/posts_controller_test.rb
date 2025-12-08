require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @post = posts(:alice_post)
    @theme = themes(:build_in_public)
  end

  test "show displays post" do
    get post_path(@post)
    assert_response :success
    assert_select "body"
  end

  test "show displays replies" do
    get post_path(@post)
    assert_response :success
  end

  test "create requires authentication" do
    post posts_path, params: { post: { body: "Test post" } }
    assert_redirected_to new_user_session_path
  end

  test "create post as authenticated user" do
    sign_in @user

    assert_difference "Post.count", 1 do
      post posts_path, params: { post: { body: "New test post" } }
    end

    assert_redirected_to timeline_path
  end

  test "create post with theme" do
    sign_in @user

    assert_difference "Post.count", 1 do
      post posts_path, params: { post: { body: "Themed post for testing", theme_id: @theme.id } }
    end

    new_post = Post.find_by(body: "Themed post for testing")
    assert_not_nil new_post, "Post should be created"
    assert_equal @theme.id, new_post.theme_id
  end

  test "create post with blank theme_id converts to nil" do
    sign_in @user

    assert_difference "Post.count", 1 do
      post posts_path, params: { post: { body: "No theme post", theme_id: "" } }
    end

    new_post = Post.last
    assert_nil new_post.theme_id
  end

  test "create reply to post" do
    sign_in @user
    parent = posts(:bob_post)

    assert_difference "Post.count", 1 do
      post posts_path, params: { post: { body: "Reply content for testing", parent_id: parent.id } }
    end

    reply = Post.find_by(body: "Reply content for testing")
    assert_not_nil reply, "Reply should be created"
    assert_equal parent.id, reply.parent_id
  end

  test "create post with invalid params shows error" do
    sign_in @user

    assert_no_difference "Post.count" do
      post posts_path, params: { post: { body: "" } }
    end

    assert_redirected_to timeline_path
    assert_equal "Body can't be blank", flash[:alert]
  end

  test "destroy requires authentication" do
    delete post_path(@post)
    assert_redirected_to new_user_session_path
  end

  test "destroy own post" do
    sign_in @user
    # Create a fresh post without replies to delete
    post_to_delete = Post.create!(user: @user, body: "Post to delete")

    assert_difference "Post.count", -1 do
      delete post_path(post_to_delete)
    end

    assert_redirected_to timeline_path
  end

  test "cannot destroy other users post" do
    sign_in users(:bob)

    assert_no_difference "Post.count" do
      delete post_path(@post)
    end

    assert_redirected_to timeline_path
    assert_equal "Not authorized", flash[:alert]
  end

  test "create responds to turbo_stream" do
    sign_in @user

    post posts_path, params: { post: { body: "Turbo test" } }, as: :turbo_stream
    assert_response :success
  end

  test "destroy responds to turbo_stream" do
    sign_in @user

    delete post_path(@post), as: :turbo_stream
    assert_response :success
  end

  test "create post with image" do
    sign_in @user

    image = fixture_file_upload("test_image.jpg", "image/jpeg")

    assert_difference "Post.count", 1 do
      post posts_path, params: { post: { body: "Post with image", image: image } }
    end

    new_post = Post.find_by(body: "Post with image")
    assert_not_nil new_post
    assert new_post.image.attached?
    assert_redirected_to timeline_path
  end

  test "create post with invalid image type shows error" do
    sign_in @user

    invalid_file = fixture_file_upload("test_file.txt", "text/plain")

    assert_no_difference "Post.count" do
      post posts_path, params: { post: { body: "Post with invalid file", image: invalid_file } }
    end

    assert_redirected_to timeline_path
    assert_match(/must be a JPEG, PNG, GIF, or WebP/, flash[:alert])
  end
end
