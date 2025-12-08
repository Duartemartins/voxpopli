require "test_helper"

class ThemeTest < ActiveSupport::TestCase
  test "valid theme" do
    theme = Theme.new(name: "New Theme")
    assert theme.valid?
  end

  test "requires name" do
    theme = Theme.new(name: nil)
    assert_not theme.valid?
    assert_includes theme.errors[:name], "can't be blank"
  end

  test "requires unique name" do
    existing = themes(:build_in_public)

    duplicate = Theme.new(name: existing.name)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "requires unique slug" do
    existing = themes(:build_in_public)

    # Create theme with different name but same slug
    duplicate = Theme.new(name: "Different Name", slug: existing.slug)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "generates slug from name on create" do
    theme = Theme.create!(name: "My New Theme")
    assert_equal "my-new-theme", theme.slug
  end

  test "does not overwrite existing slug" do
    theme = Theme.new(name: "Custom", slug: "my-custom-slug")
    theme.save!
    assert_equal "my-custom-slug", theme.slug
  end

  test "to_param returns slug" do
    theme = themes(:build_in_public)
    assert_equal theme.slug, theme.to_param
  end

  test "nullifies posts when destroyed" do
    theme = themes(:build_in_public)
    post = posts(:alice_post)

    assert_equal theme, post.theme

    theme.destroy

    post.reload
    assert_nil post.theme_id
  end
end
