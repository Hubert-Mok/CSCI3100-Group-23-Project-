import { Controller } from "@hotwired/stimulus"

// Scrolls a messages container to the bottom on connect and whenever the
// element receives a Turbo Stream update.
export default class extends Controller {
  connect() {
    this.scrollToBottom()
  }

  scrollToBottom() {
    // Use requestAnimationFrame to ensure the DOM has been painted
    requestAnimationFrame(() => {
      this.element.scrollTop = this.element.scrollHeight
    })
  }
}

