require "test_helper"

class ApplicationMailerTest < ActionMailer::TestCase
  test "default from address is set" do
    assert_equal "from@example.com", ApplicationMailer.default[:from]
  end

  test "uses mailer layout" do
    # ApplicationMailer sets the layout to "mailer"
    assert_equal "mailer", ApplicationMailer._layout
  end
end
