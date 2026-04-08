# lib/tasks/dev.rake
namespace :dev do
  desc "Reset sample products (asks for confirmation)"
  task reset_samples: :environment do
    abort "Only allowed in development" unless Rails.env.development?

    puts "\n⚠️  This will DELETE ALL PRODUCTS and LIKES from the database!"
    puts "Are you sure? Type Y to continue, anything else to cancel."
    answer = STDIN.gets.chomp.strip.upcase

    if answer == "Y"
      Like.delete_all
      Product.delete_all
      ActiveRecord::Base.connection.execute("ALTER SEQUENCE products_id_seq RESTART WITH 1;")
      puts "Sample data reset complete."
      Rake::Task["db:seed"].invoke   # re-run normal seeds after reset
    else
      puts "Reset cancelled."
    end
  end
end
