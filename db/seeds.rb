# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb
# db/seeds.rb

puts "🌱 Seeding sample data..."

# ── Users ──────────────────────────────────────────────
users_data = [
  { email: "seller1@cuhk.edu.hk", password: "spassword1", username: "seller1", cuhk_id: "1155111111", college_affiliation: "United College" },
  { email: "seller2@cuhk.edu.hk", password: "spassword2", username: "seller2", cuhk_id: "1155222222", college_affiliation: "Shaw College" },
  { email: "buyer3@cuhk.edu.hk", password: "bpassword3", username: "buyer3", cuhk_id: "1155333333", college_affiliation: "New Asia College" },
  { email: "alice@cuhk.edu.hk", password: "apassword4", username: "alice_shop", cuhk_id: "1155444444", college_affiliation: "Chung Chi College" },
  { email: "bob@cuhk.edu.hk", password: "bpassword5", username: "bob_deals", cuhk_id: "1155555555", college_affiliation: "S.H. Ho College" },
  { email: "carol@cuhk.edu.hk", password: "cpassword6", username: "carol_mart", cuhk_id: "1155666666", college_affiliation: "Morningside College" },
  { email: "dave@cuhk.edu.hk", password: "dpassword7", username: "dave_sells", cuhk_id: "1155777777", college_affiliation: "Lee Woo Sing College" },
  { email: "emma@cuhk.edu.hk", password: "epassword8", username: "emma_finds", cuhk_id: "1155888888", college_affiliation: "Wu Yee Sun College" },
]

users = users_data.map do |data|
  User.find_or_create_by!(email: data[:email]) do |u|
    u.password              = u.password_confirmation = data[:password]
    u.username              = data[:username]
    u.cuhk_id              = data[:cuhk_id]
    u.college_affiliation  = data[:college_affiliation]
  end
end

puts "✅ #{users.count} users ready."

# ── Products ───────────────────────────────────────────
if Product.count.zero?
  puts "Creating sample products..."

  products_data = [
    # Books & Notes
    { title: "CSCI2100 Data Structures Textbook", description: "Barely used textbook for CSCI2100. No highlights or markings. Covers arrays, linked lists, trees, graphs, and sorting algorithms. Perfect for next semester students.", price: 120.00, status: "available", listing_type: "sale", category: "Books & Notes", user: users[0] },
    { title: "MATH1010 Lecture Notes Bundle", description: "Complete set of handwritten lecture notes for MATH1010 University Mathematics. Includes all tutorials and past paper solutions from 2024-2025.", price: 0.00, status: "available", listing_type: "gift", category: "Books & Notes", user: users[3], thumbnail: "handwritten_lecture_notes.jpg" },

    # Electronics
    { title: "iPhone 14 Pro - 128GB Space Black", description: "Used for one year, battery health 89%. Comes with original box and charger. Minor scratches on the back, screen protector always on. No Face ID issues.", price: 3500.00, status: "available", listing_type: "sale", category: "Electronics", user: users[0] },
    { title: "iPad Air 5th Gen with Apple Pencil", description: "Great for note-taking. 64GB WiFi model in blue. Includes Apple Pencil 2nd gen and a magnetic case. Screen in perfect condition.", price: 2800.00, status: "reserved", listing_type: "sale", category: "Electronics", user: users[4] },
    { title: "Sony WH-1000XM4 Headphones", description: "Noise cancelling headphones in black. Amazing sound quality. Comes with carrying case and aux cable. Battery lasts 30 hours.", price: 800.00, status: "available", listing_type: "sale", category: "Electronics", user: users[1], thumbnail: "headphones.jpg" },

    # Clothing & Accessories
    { title: "Uniqlo Down Jacket - Size M", description: "Ultra light down jacket in navy blue. Worn only twice last winter. No stains or damage. Comes with original pouch for compact storage.", price: 380.00, status: "available", listing_type: "sale", category: "Clothing & Accessories", user: users[0], thumbnail: "jacket.jpg" },
    { title: "Nike Air Force 1 - Size US 9", description: "White AF1s, worn for about 3 months. Some creasing on the toe box but overall clean. Soles still in great shape.", price: 350.00, status: "sold", listing_type: "sale", category: "Clothing & Accessories", user: users[5] },

    # Furniture & Home
    { title: "IKEA ALEX Desk - White", description: "Study desk with two drawers. 131x60cm. Minor scratches on the surface. Must pick up from university dorm area. Disassembly needed.", price: 250.00, status: "available", listing_type: "sale", category: "Furniture & Home", user: users[1], thumbnail: "ikea_alex_desk.jpg" },
    { title: "Desk Lamp - LED Adjustable", description: "USB rechargeable desk lamp with 3 brightness levels. Used for one semester. Giving away because I'm graduating.", price: 0.00, status: "available", listing_type: "gift", category: "Furniture & Home", user: users[6], thumbnail: "lamp.jpg" },

    # Sports & Fitness
    { title: "Yoga Mat - 6mm Thick", description: "Purple yoga mat, used a few times. Non-slip surface, comes with carrying strap. Great for beginners or gym sessions.", price: 80.00, status: "available", listing_type: "sale", category: "Sports & Fitness", user: users[3], thumbnail: "yoga_mat.jpg" },
    { title: "Badminton Racket - Yonex Astrox", description: "Yonex Astrox 88D Pro racket. Restrung last month. Grip tape recently replaced. Perfect for intermediate to advanced players.", price: 450.00, status: "available", listing_type: "sale", category: "Sports & Fitness", user: users[7], thumbnail: "badminton_racket.jpg" },

    # Stationery & Supplies
    { title: "Muji Gel Pens - Pack of 10", description: "Brand new unopened pack of Muji 0.5mm gel pens in assorted colours. Bought extra by mistake.", price: 45.00, status: "available", listing_type: "sale", category: "Stationery & Supplies", user: users[2], thumbnail: "Muji_pen.jpg" },
    { title: "Scientific Calculator - Casio fx-991EX", description: "Required for many CUHK courses. Works perfectly. Includes protective cover.", price: 90.00, status: "available", listing_type: "sale", category: "Stationery & Supplies", user: users[4], thumbnail: "calculator.jpg" },

    # Food & Drinks
    { title: "Instant Noodle Collection", description: "Moving out sale! 15 packs of assorted instant noodles (Shin Ramyun, Indomie, Nissin). All within expiry date. Free pickup at Shaw College.", price: 0.00, status: "available", listing_type: "gift", category: "Food & Drinks", user: users[1], thumbnail: "instant_noodle.jpg" },

    # Tickets & Vouchers
    { title: "CUHK Gym Membership - 3 Months", description: "Transferable gym membership valid until August 2026. Includes access to swimming pool and fitness centre. Selling because I'm going on exchange.", price: 200.00, status: "available", listing_type: "sale", category: "Tickets & Vouchers", user: users[5] },
    { title: "Starbucks Gift Card - $100", description: "Starbucks gift card with $100 balance. Selling at a discount. Can verify balance in store together.", price: 85.00, status: "available", listing_type: "sale", category: "Tickets & Vouchers", user: users[7], thumbnail: "gift_card.jpg" },

    # Services
    { title: "Math Tutoring - MATH1010/1020", description: "Offering tutoring for university math courses. Scored A in both. $120/hour, flexible schedule. Can meet on campus or online via Zoom.", price: 120.00, status: "available", listing_type: "sale", category: "Services", user: users[6] },

    # Others
    { title: "Moving Out Bundle - Kitchen Items", description: "Graduating and moving out! Includes electric kettle, rice cooker, plates, cups, and utensils. Everything must go. Prefer to sell as a bundle.", price: 150.00, status: "available", listing_type: "sale", category: "Others", user: users[3], thumbnail: "kitchen_item.jpg" },
    { title: "Free Board Games Collection", description: "Settlers of Catan, Codenames, and Uno. All complete with no missing pieces. Great for hall gatherings. Pickup at United College.", price: 0.00, status: "available", listing_type: "gift", category: "Others", user: users[0], thumbnail: "boardgame.jpg" },
  ]

  products_data.each do |data|
    product = Product.create!(data.except(:thumbnail))
    puts "  Created: #{data[:title]}"

    # Attach image safely
    if data[:thumbnail].present?
      image_path = Rails.root.join('db', 'seeds', 'images', data[:thumbnail])

      if File.exist?(image_path)
        begin
          product.thumbnail.attach(
            io: File.open(image_path),
            filename: data[:thumbnail],
            content_type: "image/jpeg"
          )
          puts "    → Attached image: #{data[:thumbnail]}"
        rescue => e
          puts "    ⚠️  Failed to attach image #{data[:thumbnail]}: #{e.message}"
        end
      else
        puts "    ⚠️  Image not found: #{data[:thumbnail]}"
      end
    end
  end

  puts "✅ #{Product.count} products created."
else
  puts "⏭️  Products already exist, skipping product seeding."
end

# ── Likes ──────────────────────────────────────────────
if Like.count.zero?
  puts "Creating sample likes..."

  products = Product.all.to_a
  buyers = users[2..7] # buyers who like things

  buyers.each do |buyer|
    products.sample(rand(3..6)).each do |product|
      next if product.user == buyer # don't like your own product
      Like.find_or_create_by!(user: buyer, product: product)
    end
  end

  # Update likes_count cache
  Product.find_each do |product|
    Product.reset_counters(product.id, :likes)
  end

  puts "✅ #{Like.count} likes created."
else
  puts "⏭️  Likes already exist, skipping."
end

puts ""
puts "🎉 Seeding complete!"
puts ""
puts "Login credentials:"
puts "──────────────────────────────────────"
puts "  seller1@cuhk.edu.hk  /  spassword1"
puts "  seller2@cuhk.edu.hk  /  spassword2"
puts "  buyer3@cuhk.edu.hk   /  bpassword3"
puts "  alice@cuhk.edu.hk    /  apassword4"
puts "  bob@cuhk.edu.hk      /  bpassword5"
puts "  carol@cuhk.edu.hk    /  cpassword6"
puts "  dave@cuhk.edu.hk     /  dpassword7"
puts "  emma@cuhk.edu.hk     /  epassword8"
puts "──────────────────────────────────────"