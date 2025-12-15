import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { content: String, successText: String }
  
  copy() {
    const originalText = this.element.textContent
    const successText = this.successTextValue || "COPIED!"
    
    navigator.clipboard.writeText(this.contentValue).then(() => {
      this.element.textContent = successText
      setTimeout(() => {
        this.element.textContent = originalText
      }, 2000)
    }).catch(err => {
      console.error('Failed to copy:', err)
    })
  }
}
