module FraudDetectable
  extend ActiveSupport::Concern

  def get_ai_fraud_score
    begin
      response = HTTParty.post("http://localhost:8000/analyze", 
        body: { 
          price: self.price.to_f, 
          title_len: self.title.length, 
          desc_len: self.description.length 
        }.to_json,
        headers: { 'Content-Type' => 'application/json' },
        timeout: 2
      )

      if response.success?
        { score: response["fraud_score"], is_fraud: response["is_fraud"]}
      else
        { score: 0.0, is_fraud: false }
      end
    rescue StandardError => e
      Rails.logger.error "AI API Down: #{e.message}"
      { score: 0.0, is_fraud: false }
    end
  end
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
    #check blacklist patterns
    return true if SUSPICIOUS_PATTERNS.any? { |pattern| content.match?(pattern) }
    false
  end

  def flag_for_review!
    # This assumes you add a 'flagged' boolean or 'status' column to your models
    update(flagged: true) 
  end
end
