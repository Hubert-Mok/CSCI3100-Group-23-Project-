# frozen_string_literal: true

namespace :marketplace do
  desc "Re-upload product thumbnails from db/seeds/images when blobs are missing or unreadable (e.g. after switching Disk -> Azure)"
  task repair_seed_thumbnails: :environment do
    images_dir = Rails.root.join("db", "seeds", "images")
    unless images_dir.directory?
      puts "No #{images_dir}; nothing to do."
      next
    end

    fixed = 0
    skipped = 0
    errors = 0

    Product.find_each do |product|
      unless product.thumbnail.attached?
        skipped += 1
        next
      end

      blob = product.thumbnail.blob
      filename = blob.filename.to_s
      seed_path = images_dir.join(filename)

      readable = false
      begin
        product.thumbnail.download
        readable = true
      rescue StandardError
      end

      if readable
        skipped += 1
        next
      end

      unless seed_path.file?
        puts "SKIP product #{product.id}: not readable and no seed file #{filename}"
        skipped += 1
        next
      end

      begin
        product.thumbnail.purge
        product.thumbnail.attach(
          io: File.open(seed_path),
          filename: filename,
          content_type: blob.content_type.presence || "image/jpeg"
        )
        fixed += 1
        puts "OK product #{product.id}: re-attached #{filename} -> #{Rails.application.config.active_storage.service}"
      rescue StandardError => e
        errors += 1
        puts "ERR product #{product.id}: #{e.class}: #{e.message}"
      end
    end

    summary = { fixed: fixed, skipped: skipped, errors: errors }
    puts "Done: #{summary.inspect}"
  end
end
