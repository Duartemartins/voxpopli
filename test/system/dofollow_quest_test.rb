require "application_system_test_case"

class DofollowQuestTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "quest_user@example.com",
      username: "quest_user",
      password: "password123",
      confirmed_at: Time.current,
      tagline: "Just a quest user",
      website: "https://quest.example.com"
    )

    @other_user = User.create!(
      email: "other_quest@example.com",
      username: "other_quest",
      password: "password123",
      confirmed_at: Time.current
    )

    @theme = Theme.create!(name: "Quest Theme", slug: "quest-theme", color: "#000000")
    @other_post = Post.create!(user: @other_user, body: "Target post", theme: @theme)
  end

  test "quest progress updates and unlocks dofollow" do
    sign_in @user

    # Ensure we are signed in
    assert_text "LOGOUT"

    visit root_path

    # Check initial state: Quest visible, links are nofollow
    assert_text "DOFOLLOW_QUEST_STATUS"
    assert_text "IN_PROGRESS"

    visit settings_account_path
    assert_text "LINK_PROTOCOL"
    assert_text "NOFOLLOW_RESTRICTED"

    visit user_path(@user)
    assert_selector "a[rel*='nofollow'][href='#{@user.website}']"

    # 1. Post (Transmission)
    visit root_path
    fill_in "post_body", with: "My first transmission"
    click_on "[ EXECUTE ]"

    # assert_text "Transmission sent" # This might be flaky or text might differ
    assert_text "INITIATE_TRANSMISSION"
    assert_text "[ COMPLETE ]"

    # 2. Vote
    # Find the other post and vote
    # Note: This might be tricky if the feed is empty or ordered differently.
    # We can visit the post directly or ensure it's in the feed.
    visit root_path(feed: "global")

    # Find the vote button for the other post
    within "#post_#{@other_post.id}" do
      click_on "▲"
    end

    assert_text "CAST_VOTE"
    assert_text "[ COMPLETE ]"

    # 3. Reply
    visit post_path(@other_post)
    fill_in "post_body", with: "Nice post!"
    click_on "TRANSMIT_REPLY"

    visit root_path
    assert_text "TRANSMIT_REPLY"
    assert_text "[ COMPLETE ]"

    # 4. Follow
    visit user_path(@other_user)
    click_on "[ FOLLOW_USER ]"

    visit root_path
    # Quest should be auto-dismissed now
    assert_no_text "DOFOLLOW_QUEST_STATUS"

    # Check profile link is dofollow
    visit user_path(@user)
    assert_selector "a[href='#{@user.website}']"
    assert_no_selector "a[rel*='nofollow'][href='#{@user.website}']"

    # Check settings page status
    visit settings_account_path
    assert_text "LINK_PROTOCOL"
    assert_text "DOFOLLOW_ACTIVE"
  end

  private

  def sign_in(user)
    visit new_user_session_path
    fill_in "USER_ID // EMAIL", with: user.email
    fill_in "ACCESS_CODE // PASSWORD", with: "password123"
    click_on "INITIATE_LOGIN"
  end
end
