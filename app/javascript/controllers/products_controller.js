import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="products"
export default class extends Controller {
  static targets = ["container", "template", "empty"]

  connect() {
    this.index = this.containerTarget.querySelectorAll('.product-entry').length
  }

  add(event) {
    event.preventDefault()
    
    const content = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, this.index)
    this.containerTarget.insertAdjacentHTML('beforeend', content)
    this.index++
    
    // Hide empty message if it exists
    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.add('hidden')
    }
  }

  remove(event) {
    event.preventDefault()
    
    const entry = event.target.closest('.product-entry')
    if (entry) {
      entry.remove()
    }
    
    // Show empty message if no products left
    if (this.hasEmptyTarget && this.containerTarget.querySelectorAll('.product-entry').length === 0) {
      this.emptyTarget.classList.remove('hidden')
    }
  }
}
