# Create initial themes
themes = [
  { name: 'Build in Public', slug: 'build-in-public', description: 'Share your building journey with the community', color: '#6366f1' },
  { name: 'Launch', slug: 'launch', description: 'Announce your product launches', color: '#10b981' },
  { name: 'Milestone', slug: 'milestone', description: 'Celebrate your achievements', color: '#f59e0b' },
  { name: 'Question', slug: 'question', description: 'Ask the community for help', color: '#3b82f6' },
  { name: 'Feedback', slug: 'feedback', description: 'Request feedback on your work', color: '#8b5cf6' }
]

themes.each do |theme_attrs|
  Theme.find_or_create_by!(slug: theme_attrs[:slug]) do |t|
    t.name = theme_attrs[:name]
    t.description = theme_attrs[:description]
    t.color = theme_attrs[:color]
  end
end

# Create initial admin invites
10.times do
  Invite.create!(expires_at: 1.month.from_now)
end

puts "Created #{Theme.count} themes"
puts ""
puts "Created 10 invite codes:"
Invite.order(:created_at).last(10).each { |i| puts "  #{i.code}" }
puts ""
puts "Use one of these invite codes to register at: /users/sign_up?invite_code=CODE"
