module FraudDetectable
  extend ActiveSupport::Concern

  # Patterns to flag: Phone numbers, common scam apps, and payment keywords
  SUSPICIOUS_PATTERNS = [
    /\+?\d{8,15}/,          # Phone numbers (8-15 digits)
    /whatsapp/i,            # WhatsApp (case insensitive)
    /telegram/i,            # Telegram
    /gift card/i,           # Common scam payment
    /western union/i,       # Common scam payment
    /pay\s*outside/i        # "Pay outside"
  ]

  def suspicious?
    # Check 'body' (for Messages) or 'description' (for Products)
    content = self.try(:body) || self.try(:description)
    return false if content.blank?

    SUSPICIOUS_PATTERNS.any? { |pattern| content.match?(pattern) }
  end

  def flag_for_review!
    # This assumes you add a 'flagged' boolean or 'status' column to your models
    update(flagged: true) 
  end
end
