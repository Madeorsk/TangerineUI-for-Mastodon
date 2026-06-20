# Rich dev fixtures: public posts, a DM, a boost, favourites/follow notifications, a custom emoji. Safe to re-run.
# Requires the `admin` account from `rails db:setup`.

domain = (ENV['LOCAL_DOMAIN'] || 'localhost:3000').gsub(/:\d+$/, '')

admin = Account.find_by(username: 'admin')
abort 'admin account missing; run `./dev.sh init` first.' unless admin

tester_account = Account.where(username: 'tester').first_or_initialize(username: 'tester')
tester_account.save(validate: false)
User.where(email: "tester@#{domain}").first_or_create!(
  email: "tester@#{domain}",
  password: 'mastodonadmin',
  password_confirmation: 'mastodonadmin',
  confirmed_at: Time.now.utc,
  account: tester_account,
  agreement: true,
  approved: true,
  bypass_registration_checks: true
)

# Print failures instead of hiding them, so a broken fixture is visible.
step = lambda do |label, &block|
  block.call
  puts "  ok: #{label}"
rescue => e
  puts "  FAILED: #{label} -> #{e.class}: #{e.message}"
end

post = ->(account, text, **opts) { PostStatusService.new.call(account, text:, **opts) }

admin_status = nil
tester_status = nil
step.call('admin public post') { admin_status = post.call(admin, "Testing Tangerine UI 🍊 a public post with a #hashtag and a link https://github.com/madeorsk/TangerineUI-for-Mastodon") }
step.call('tester public post') { tester_status = post.call(tester_account, "Hello @admin, boost me to test the timeline! #tangerineui") }
step.call('admin follows tester') { FollowService.new.call(admin, tester_account) }
step.call('tester follows admin') { FollowService.new.call(tester_account, admin) }
step.call('admin boosts tester') { ReblogService.new.call(admin, tester_status) if tester_status }
step.call('tester favourites admin') { FavouriteService.new.call(tester_account, admin_status) if admin_status }
step.call('tester DMs admin') { post.call(tester_account, "@admin secret DM to check the distinct DM styling 🤫", visibility: 'direct') }

step.call('custom emoji') do
  emoji = '/workspace/art/Logo_Wide.png'
  if File.exist?(emoji) && !CustomEmoji.exists?(shortcode: 'tangerine', domain: nil)
    CustomEmoji.create!(shortcode: 'tangerine', image: File.open(emoji))
  end
end

puts "Seed complete. Login: admin@#{domain} / mastodonadmin"
