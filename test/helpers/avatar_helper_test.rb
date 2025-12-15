require "test_helper"

class AvatarHelperTest < ActionView::TestCase
  test "user_avatar returns image tag when avatar is attached" do
    user = users(:alice)
    user.avatar.attach(io: File.open(Rails.root.join("test/fixtures/files/test_image.jpg")), filename: "test_image.jpg", content_type: "image/jpeg")

    result = user_avatar(user)
    assert_match /<img.*src=".*".*>/, result
    assert_match /class="w-10 h-10 object-cover border border-steel bg-carbon"/, result
  end

  test "user_avatar returns minidenticon svg when avatar is not attached" do
    user = users(:bob)
    # Ensure no avatar is attached
    user.avatar.purge if user.avatar.attached?

    result = user_avatar(user)
    assert_match /<minidenticon-svg/, result
    assert_match /username="bob"/, result
    assert_match /style="color: #CCFF00;"/, result
    assert_match /class="w-10 h-10 border border-steel bg-carbon block"/, result
  end

  test "user_avatar accepts custom classes" do
    user = users(:bob)
    result = user_avatar(user, classes: "w-20 h-20")
    assert_match /class="w-20 h-20 border border-steel bg-carbon block"/, result
  end
end
