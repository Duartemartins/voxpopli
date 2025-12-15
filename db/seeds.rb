# Clear existing data (order matters due to foreign keys)
puts "Clearing existing data..."
Notification.destroy_all
Bookmark.destroy_all
Vote.destroy_all
Follow.destroy_all
Post.destroy_all
ApiKey.destroy_all
Webhook.destroy_all
User.destroy_all
Invite.destroy_all
Theme.destroy_all

# Create initial themes
themes = [
  { name: 'Build in Public', slug: 'build-in-public', description: 'Share your building journey with the community', color: '#003399' }
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

# Create test users with builder profile data
users_data = [
  {
    email: 'alice@example.com',
    username: 'alice',
    display_name: 'Alice Builder',
    bio: 'Building cool stuff. Indie hacker. Coffee enthusiast.',
    tagline: 'Shipping indie products one coffee at a time',
    github_username: 'alicebuilder',
    skills: [ 'Ruby', 'Rails', 'JavaScript', 'Tailwind CSS' ],
    looking_for: 'cofounders',
    website: 'https://alicebuilder.dev',
    launched_products: [
      { 'name' => 'TaskFlow', 'url' => 'https://taskflow.app', 'description' => 'Simple task management for indie hackers', 'mrr' => 2500, 'revenue_confirmed' => true },
      { 'name' => 'LaunchKit', 'url' => 'https://launchkit.io', 'description' => 'Landing page templates for SaaS', 'mrr' => 800, 'revenue_confirmed' => true }
    ]
  },
  {
    email: 'bob@example.com',
    username: 'bob',
    display_name: 'Bob Developer',
    bio: 'Full-stack developer shipping products every week.',
    tagline: 'Full-stack dev obsessed with developer tools',
    github_username: 'bobthedev',
    skills: [ 'TypeScript', 'React', 'Node.js', 'PostgreSQL', 'AWS' ],
    looking_for: 'beta_testers',
    website: 'https://bobdev.io',
    launched_products: [
      { 'name' => 'DevDash', 'url' => 'https://devdash.dev', 'description' => 'Dashboard for monitoring your side projects', 'mrr' => 1200, 'revenue_confirmed' => true },
      { 'name' => 'APIspy', 'url' => 'https://apispy.io', 'description' => 'API monitoring and alerting', 'mrr' => 450, 'revenue_confirmed' => false }
    ]
  },
  {
    email: 'carol@example.com',
    username: 'carol',
    display_name: 'Carol Designer',
    bio: 'UX/UI designer turned founder. Building in public.',
    tagline: 'Design-first founder building beautiful SaaS',
    github_username: 'caroldesigns',
    skills: [ 'Figma', 'UI Design', 'UX Research', 'Framer', 'CSS' ],
    looking_for: 'feedback',
    website: 'https://caroldesigns.co',
    launched_products: [
      { 'name' => 'DesignSystem.io', 'url' => 'https://designsystem.io', 'description' => 'Pre-built design systems for startups', 'mrr' => 3200, 'revenue_confirmed' => true }
    ]
  },
  {
    email: 'dave@example.com',
    username: 'dave',
    display_name: 'Dave Founder',
    bio: 'Serial entrepreneur. Failed 3 times, working on #4.',
    tagline: 'Building startup #4. This time it will work.',
    github_username: 'davefounder',
    skills: [ 'Python', 'Django', 'Machine Learning', 'Data Science' ],
    looking_for: 'investors',
    website: 'https://davebuilds.com',
    launched_products: [
      { 'name' => 'DataPipe', 'url' => 'https://datapipe.ai', 'description' => 'ETL pipelines made simple', 'mrr' => 5000, 'revenue_confirmed' => true },
      { 'name' => 'MLKit', 'url' => 'https://mlkit.dev', 'description' => 'No-code ML model deployment', 'mrr' => 1800, 'revenue_confirmed' => true },
      { 'name' => 'ChurnStop', 'url' => 'https://churnstop.io', 'description' => 'Predict and prevent customer churn', 'mrr' => 750, 'revenue_confirmed' => false }
    ]
  },
  {
    email: 'emma@example.com',
    username: 'emma',
    display_name: 'Emma Tech',
    bio: 'SaaS builder. Love automation and productivity tools.',
    tagline: 'Automating everything that can be automated',
    github_username: 'emmatech',
    skills: [ 'Go', 'Rust', 'Kubernetes', 'DevOps', 'Terraform' ],
    looking_for: 'hiring',
    website: 'https://emmatech.dev',
    launched_products: [
      { 'name' => 'AutoDeploy', 'url' => 'https://autodeploy.sh', 'description' => 'One-click deployments for indie hackers', 'mrr' => 4200, 'revenue_confirmed' => true }
    ]
  },
  {
    email: 'frank@example.com',
    username: 'frank',
    display_name: 'Frank Maker',
    bio: 'Hardware meets software. Building IoT products.',
    tagline: 'Bridging hardware and software with IoT',
    github_username: 'frankmaker',
    skills: [ 'Arduino', 'Raspberry Pi', 'Python', 'C++', 'Electronics' ],
    looking_for: 'cofounders',
    website: 'https://frankmaker.io',
    launched_products: [
      { 'name' => 'SensorHub', 'url' => 'https://sensorhub.io', 'description' => 'IoT sensor management platform', 'mrr' => 1500, 'revenue_confirmed' => true }
    ]
  },
  {
    email: 'grace@example.com',
    username: 'grace',
    display_name: 'Grace Growth',
    bio: 'Growth marketer building marketing tools.',
    tagline: 'Marketing automation for bootstrapped founders',
    github_username: nil,
    skills: [ 'Marketing', 'SEO', 'Content Strategy', 'Analytics' ],
    looking_for: 'beta_testers',
    website: 'https://gracegrowth.co',
    launched_products: [
      { 'name' => 'GrowthBot', 'url' => 'https://growthbot.io', 'description' => 'AI-powered marketing assistant', 'mrr' => 2800, 'revenue_confirmed' => true },
      { 'name' => 'SEOPilot', 'url' => 'https://seopilot.co', 'description' => 'Automated SEO recommendations', 'mrr' => 900, 'revenue_confirmed' => false }
    ]
  },
  {
    email: 'henry@example.com',
    username: 'henry',
    display_name: 'Henry Hacker',
    bio: 'Security researcher turned founder.',
    tagline: 'Making security accessible for small teams',
    github_username: 'henryhacker',
    skills: [ 'Security', 'Penetration Testing', 'Python', 'Go' ],
    looking_for: 'nothing',
    website: 'https://henryhacker.security',
    launched_products: [
      { 'name' => 'SecureScan', 'url' => 'https://securescan.io', 'description' => 'Vulnerability scanning for startups', 'mrr' => 6500, 'revenue_confirmed' => true }
    ]
  }
]

users = users_data.map do |user_data|
  User.create!(
    email: user_data[:email],
    username: user_data[:username],
    display_name: user_data[:display_name],
    bio: user_data[:bio],
    tagline: user_data[:tagline],
    github_username: user_data[:github_username],
    skills: user_data[:skills],
    looking_for: user_data[:looking_for],
    website: user_data[:website],
    launched_products: user_data[:launched_products],
    password: 'password123',
    password_confirmation: 'password123',
    confirmed_at: Time.current
  )
end

# Create some follows between users
users[0].follow(users[1]) # alice follows bob
users[0].follow(users[2]) # alice follows carol
users[0].follow(users[4]) # alice follows emma
users[0].follow(users[7]) # alice follows henry
users[1].follow(users[0]) # bob follows alice
users[1].follow(users[3]) # bob follows dave
users[1].follow(users[5]) # bob follows frank
users[2].follow(users[0]) # carol follows alice
users[2].follow(users[4]) # carol follows emma
users[2].follow(users[6]) # carol follows grace
users[3].follow(users[1]) # dave follows bob
users[3].follow(users[7]) # dave follows henry
users[4].follow(users[2]) # emma follows carol
users[4].follow(users[3]) # emma follows dave
users[5].follow(users[0]) # frank follows alice
users[5].follow(users[4]) # frank follows emma
users[6].follow(users[0]) # grace follows alice
users[6].follow(users[2]) # grace follows carol
users[6].follow(users[3]) # grace follows dave
users[7].follow(users[1]) # henry follows bob
users[7].follow(users[3]) # henry follows dave
users[7].follow(users[4]) # henry follows emma

# Create test posts
posts_data = [
  { user: users[0], theme: 'build-in-public', body: 'Just launched my first SaaS product! Built it in 2 weeks using Rails 8. So excited to see where this goes!' },
  { user: users[1], theme: 'build-in-public', body: 'Hit $1,000 MRR today! Started from $0 just 3 months ago. The grind is real but so worth it.' },
  { user: users[2], theme: 'build-in-public', body: 'What\'s your go-to tech stack for MVPs? Looking to build fast and iterate quickly.' },
  { user: users[0], theme: 'build-in-public', body: 'Day 15 of building: Added authentication, payment integration, and the core features. Launch is scheduled for next Monday!' },
  { user: users[3], theme: 'build-in-public', body: 'After 6 months of development, I\'m finally launching DataPipe today! Check it out and let me know what you think.' },
  { user: users[4], theme: 'build-in-public', body: 'Would love feedback on my landing page design. Does it clearly communicate the value prop?' },
  { user: users[1], theme: 'build-in-public', body: 'Learned a tough lesson today: validate your idea before building. Spent 3 weeks on something nobody wanted.' },
  { user: users[2], theme: 'build-in-public', body: 'Just got my first paying customer! They found me through this community. Thank you all for the support!' },
  { user: users[3], theme: 'build-in-public', body: 'How do you handle feature requests from users? Do you build everything they ask for?' },
  { user: users[4], theme: 'build-in-public', body: 'Thinking about pivoting my project. Current approach isn\'t getting traction. Should I stick it out or try something new?' },
  { user: users[0], theme: 'build-in-public', body: '100 users signed up in the first week! This is incredible. Time to focus on retention now.' },
  { user: users[1], theme: 'build-in-public', body: 'Shipping a new feature today based on user feedback. Love how responsive this community is to suggestions.' },
  { user: users[5], theme: 'build-in-public', body: 'Just finished the hardware prototype for SensorHub. Now the real work begins - building the software platform.' },
  { user: users[6], theme: 'build-in-public', body: 'GrowthBot just hit $2,800 MRR! Marketing automation for bootstrapped founders is definitely a need.' },
  { user: users[7], theme: 'build-in-public', body: 'SecureScan passed its first enterprise security audit. Big milestone for a solo founder!' },
  { user: users[5], theme: 'build-in-public', body: 'Anyone else building in the IoT space? Would love to connect with other hardware + software builders.' },
  { user: users[6], theme: 'build-in-public', body: 'SEO tip: Focus on long-tail keywords when you\'re starting out. Way easier to rank and the traffic is more qualified.' },
  { user: users[7], theme: 'build-in-public', body: 'Security doesn\'t have to be complicated. Building tools that make it accessible for small teams.' },
  { user: users[3], theme: 'build-in-public', body: 'MLKit is now live! No-code ML model deployment. Took 4 months but finally shipped it.' },
  { user: users[4], theme: 'build-in-public', body: 'AutoDeploy just crossed $4,000 MRR. One-click deployments are resonating with indie hackers.' }
]

posts = posts_data.map do |post_data|
  theme = Theme.find_by(slug: post_data[:theme])
  Post.create!(
    user: post_data[:user],
    theme: theme,
    body: post_data[:body]
  )
end

# Add some votes to posts
posts[0].votes.create!(user: users[1], value: 1) # bob upvotes alice
posts[0].votes.create!(user: users[2], value: 1) # carol upvotes alice
posts[0].votes.create!(user: users[3], value: 1) # dave upvotes alice
posts[1].votes.create!(user: users[0], value: 1) # alice upvotes bob
posts[1].votes.create!(user: users[4], value: 1) # emma upvotes bob
posts[2].votes.create!(user: users[0], value: 1) # alice upvotes carol
posts[2].votes.create!(user: users[1], value: 1) # bob upvotes carol
posts[4].votes.create!(user: users[0], value: 1) # alice upvotes dave
posts[4].votes.create!(user: users[1], value: 1) # bob upvotes dave
posts[4].votes.create!(user: users[2], value: 1) # carol upvotes dave
posts[5].votes.create!(user: users[3], value: 1) # dave upvotes emma
posts[10].votes.create!(user: users[2], value: 1) # carol upvotes alice

# Add some bookmarks
users[0].bookmarks.create!(post: posts[1]) # alice bookmarks bob's milestone
users[0].bookmarks.create!(post: posts[4]) # alice bookmarks dave's launch
users[1].bookmarks.create!(post: posts[0]) # bob bookmarks alice's launch
users[2].bookmarks.create!(post: posts[2]) # carol bookmarks her own question

# Add some replies
replies_data = [
  { parent: posts[0], user: users[1], body: 'Congrats! Rails 8 is amazing for rapid development. What features did you ship?' },
  { parent: posts[0], user: users[2], body: 'Two weeks is impressive! Did you use any templates or start from scratch?' },
  { parent: posts[0], user: users[3], body: 'Love seeing these launch stories. Best of luck! 🎉' },
  { parent: posts[1], user: users[0], body: 'That\'s huge! What was your main acquisition channel?' },
  { parent: posts[1], user: users[2], body: 'Congratulations! The first $1k is the hardest. Onwards and upwards!' },
  { parent: posts[2], user: users[0], body: 'Rails + Tailwind + Hotwire is my go-to. Fast to build, easy to iterate.' },
  { parent: posts[2], user: users[3], body: 'Next.js for frontend-heavy apps, Rails for everything else.' },
  { parent: posts[2], user: users[4], body: 'I\'ve been loving Remix lately. Great DX and performance out of the box.' },
  { parent: posts[4], user: users[0], body: 'Looks great! Would love to try it out. Is there a free tier?' },
  { parent: posts[4], user: users[2], body: 'Six months of work paying off. That\'s dedication! Good luck with the launch.' },
  { parent: posts[6], user: users[3], body: 'Been there. Validation is so underrated. At least you learned early!' },
  { parent: posts[8], user: users[0], body: 'I use a voting system for feature requests. Lets users prioritize what matters most.' },
  { parent: posts[8], user: users[4], body: 'Definitely not everything! Focus on what aligns with your vision and what most users need.' }
]

replies = replies_data.map do |reply_data|
  Post.create!(
    user: reply_data[:user],
    parent: reply_data[:parent],
    body: reply_data[:body]
  )
end

# Add replies to replies (nested conversations)
nested_replies = [
  { parent: replies[0], user: users[0], body: 'Thanks Bob! Shipped auth, payments with Stripe, and a dashboard. Keeping it minimal for now.' },
  { parent: replies[0], user: users[2], body: 'Stripe integration in 2 weeks? That\'s impressive. Any gotchas to watch out for?' },
  { parent: replies[1], user: users[0], body: 'Started from scratch but used Tailwind UI components. Saved a lot of time on the frontend.' },
  { parent: replies[3], user: users[1], body: 'Mostly Twitter/X actually! Building in public helped a lot. People love following the journey.' },
  { parent: replies[3], user: users[3], body: 'This is why I love this community. Real tactics that work!' },
  { parent: replies[5], user: users[2], body: 'Same! The Hotwire stack is so underrated. No JS framework fatigue.' },
  { parent: replies[5], user: users[4], body: 'Have you tried Stimulus? Changed how I think about frontend interactivity.' },
  { parent: replies[6], user: users[0], body: 'How do you handle the backend with Next.js? Do you use a separate API?' },
  { parent: replies[8], user: users[3], body: 'Yes! Free tier with 100 tasks/month. Pro is $9/mo for unlimited.' },
  { parent: replies[11], user: users[1], body: 'A voting system is genius. Implemented something similar and it reduced support tickets by 40%.' }
]

nested_replies.each do |reply_data|
  Post.create!(
    user: reply_data[:user],
    parent: reply_data[:parent],
    body: reply_data[:body]
  )
end

puts "Created #{Theme.count} themes"
puts "Created #{User.count} test users (all with password: password123)"
puts "Created #{Post.where(parent_id: nil).count} test posts"
puts "Created #{Post.where.not(parent_id: nil).count} replies"
puts "Created #{Vote.count} votes"
puts "Created #{Follow.count} follows"
puts "Created #{Bookmark.count} bookmarks"
puts ""
puts "Builder profiles:"
users_data.each do |u|
  products_count = u[:launched_products]&.size || 0
  puts "  #{u[:username]} (#{u[:email]}) - #{products_count} products, skills: #{u[:skills]&.join(', ')}"
end
puts ""
puts "Total products in directory: #{users_data.sum { |u| u[:launched_products]&.size || 0 }}"
puts ""
puts "Created 10 invite codes:"
Invite.order(:created_at).last(10).each { |i| puts "  #{i.code}" }
puts ""
puts "Use one of these invite codes to register at: /join"
