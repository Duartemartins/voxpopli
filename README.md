# Voxpopli

![Test Coverage](https://img.shields.io/badge/coverage-96.12%25-brightgreen)
![Ruby](https://img.shields.io/badge/ruby-3.3%2B-red)
![Rails](https://img.shields.io/badge/rails-8.0-red)

A privacy-first, open source microblogging platform. 

![Voxpopli Screenshot](public/screenshot.png)

## Features

- **Twitter-like posts** - Simple text posts without character limits
- **Invite-only registration** with email confirmation
- **Username-based URLs** for user profiles (`/users/:username`)
- **Timeline views** with "New" and "Top" sorting
- **Upvote/downvote voting** system with score calculation
- **Follows system** for personalized timelines
- **Predefined themes** - Currently "Build in Public" theme available
- **Free, Builder-friendly API** with API keys, rate limiting, and webhooks
- **Privacy-first** - no tracking, minimal data collection, easy account deletion
- **No Link Nerfing** - post whatever links you'd like
- **No Rage-content promoting algorithm**
- **Open Source**
- **Do-Follow link on your profile page**

## Tech Stack

- **Rails 8** with SQLite3
- **Tailwind CSS** for styling
- **Hotwire (Turbo + Stimulus)** for interactivity
- **Solid Queue/Cache/Cable** (no Redis needed)
- **Importmaps** (no Node.js required)
- **Kamal** for deployment

## Getting Started

### Prerequisites

- Ruby 3.3+
- SQLite3

### Installation

```bash
# Clone the repository
git clone https://github.com/duartemartins/voxpopli.git
cd voxpopli

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Start the server
bin/dev
```

### Initial Setup

After running `db:seed`, you'll get:
- "Build in Public" theme
- 10 invite codes (printed to console)
- 5 test users (all with password: `password123`)
- Sample posts to explore

Use an invite code to register at `/join`.

## API

The API is available at `/api/v1/` with the following endpoints:

- `GET /api/v1/posts` - List posts
- `GET /api/v1/posts/:id` - Get a post
- `POST /api/v1/posts` - Create a post
- `DELETE /api/v1/posts/:id` - Delete a post
- `POST /api/v1/posts/:id/vote` - Vote on a post
- `GET /api/v1/themes` - List themes
- `GET /api/v1/me` - Get current user

Authentication is done via API keys in the `Authorization` header.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT](LICENSE).
