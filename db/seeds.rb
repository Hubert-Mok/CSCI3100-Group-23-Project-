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

puts "🌱 Seeding sample data..."

User.find_or_create_by!(email: "seller1@cuhk.edu.hk") do |u|
  u.password              = u.password_confirmation = "spassword1"
  u.username              = "seller1"               
  u.cuhk_id               = "1155111111"     
  u.college_affiliation   = "United College"
end         

User.find_or_create_by!(email: "seller2@cuhk.edu.hk") do |u|
  u.password              = u.password_confirmation = "spassword2"
  u.username              = "seller2"               
  u.cuhk_id               = "1155222222"     
  u.college_affiliation   = "Shaw College"         
end

User.find_or_create_by!(email: "buyer3@cuhk.edu.hk") do |u|
  u.password              = u.password_confirmation = "bpassword3"
  u.username              = "buyer3"
  u.cuhk_id               = "1155333333"
  u.college_affiliation   = "New Asia College"
end

# Products - only create if no products exist yet
if Product.count.zero?
    puts "Creating sample products..."
    seller1 = User.find_by(email: "seller1@cuhk.edu.hk")
    if seller1
        Product.create!(
            title: "Test iPhone for Sale",
            description: "Good condition, test listing",
            price: 3500.0,
            status: "available",
            listing_type: "sale",
            category: "Electronics",
            user: seller1   # attaches to this seller
        )
        puts "Product created! ID: #{Product.last.id}"
        Product.create!(
            title: "Winter Jacket - Size M",
            description: "Uniqlo down jacket, worn twice.",
            price: 380.00,
            status: "reserved",
            listing_type: "sale",
            category: "Clothing & Accessories",
            user: seller1
        )
        puts "Product created! ID: #{Product.last.id}"
    else
    puts "Seller1 not found"
    end
    seller2 = User.find_by(email: "seller2@cuhk.edu.hk")
    if seller2
        Product.create!(
            title: "Free - University Textbooks",
            description: "CS/Math books, free pickup.",
            price: 0.00,
            status: "available",
            listing_type: "gift",
            category: "Books & Notes",
            user: seller2
        )
        puts "Product created! ID: #{Product.last.id}"
    else
    puts "Seller2 not found"
    end
else
    puts "Products already exist, skipping product seeding."
end


# Likes - only if buyer exists and products exist
#if buyer.persisted? && Product.exists?
 # Product.limit(3).each do |product|
  #  Like.find_or_create_by!(user: buyer, product: product)
  #end
#end

puts "✅ Done! Check localhost:3000 after refresh."
puts "Login examples:"
puts "- Seller1: seller1@cuhk.edu.hk / spassword1"
puts "- Seller2: seller2@cuhk.edu.hk / spassword2"
puts "- Buyer3: buyer3@cuhk.edu.hk / bpassword3"