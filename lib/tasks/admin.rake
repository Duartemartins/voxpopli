namespace :admin do
  desc "Create an admin user"
  task create: :environment do
    email = ENV["ADMIN_EMAIL"]
    password = ENV["ADMIN_PASSWORD"]
    username = ENV["ADMIN_USERNAME"] # 'admin' is reserved

    user = User.find_or_initialize_by(email: email)
    user.username = username
    user.password = password
    user.password_confirmation = password
    user.admin = true
    user.confirmed_at = Time.current # Skip email confirmation

    # Fill required fields
    user.display_name = "System Admin"
    user.bio = "System Administrator"

    if user.save
      puts "Admin user created/updated:"
      puts "Email: #{email}"
      puts "Password: #{password}"
      puts "Username: #{username}"
    else
      puts "Failed to create admin user:"
      puts user.errors.full_messages.join(", ")
    end
  end
end
