import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { content: String, successText: String }
  
  copy(event) {
    event.preventDefault()
    // Store original text to restore it later
    if (!this.originalText) {
      this.originalText = this.element.innerText
    }
    
    const successText = this.successTextValue || "COPIED!"
    
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(this.contentValue)
        .then(() => this.flashSuccess(successText))
        .catch(() => this.fallbackCopy(successText))
    } else {
      this.fallbackCopy(successText)
    }
  }

  fallbackCopy(successText) {
    const textArea = document.createElement("textarea")
    textArea.value = this.contentValue
    
    // Ensure it's not visible but part of the DOM
    textArea.style.position = "fixed"
    textArea.style.left = "-9999px"
    textArea.style.top = "0"
    document.body.appendChild(textArea)
    
    textArea.focus()
    textArea.select()
    
    try {
      const successful = document.execCommand('copy')
      if (successful) {
        this.flashSuccess(successText)
      } else {
        console.error('Fallback copy failed')
        this.flashError()
      }
    } catch (err) {
      console.error('Fallback copy error:', err)
      this.flashError()
    }
    
    document.body.removeChild(textArea)
  }

  flashSuccess(text) {
    this.element.innerText = text
    this.element.classList.add("text-acid-lime", "border-acid-lime")
    this.element.classList.remove("text-acid-cyan", "border-acid-cyan")
    
    setTimeout(() => {
      this.element.innerText = this.originalText
      this.element.classList.remove("text-acid-lime", "border-acid-lime")
      this.element.classList.add("text-acid-cyan", "border-acid-cyan")
    }, 2000)
  }

  flashError() {
    this.element.innerText = "ERROR"
    this.element.classList.add("text-acid-pink", "border-acid-pink")
    this.element.classList.remove("text-acid-cyan", "border-acid-cyan")
    
    setTimeout(() => {
      this.element.innerText = this.originalText
      this.element.classList.remove("text-acid-pink", "border-acid-pink")
      this.element.classList.add("text-acid-cyan", "border-acid-cyan")
    }, 2000)
  }
}
