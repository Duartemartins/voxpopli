// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { minidenticonSvg } from "minidenticons"

// Register minidenticons custom element
if (!customElements.get('minidenticon-svg')) {
  customElements.define('minidenticon-svg', 
    class extends HTMLElement {
      connectedCallback() {
        const username = this.getAttribute('username') || 'default'
        const saturation = this.getAttribute('saturation') || '95'
        const lightness = this.getAttribute('lightness') || '45'
        
        this.innerHTML = minidenticonSvg(username, saturation, lightness)
        
        // Copy attributes to SVG
        const svg = this.querySelector('svg')
        if (svg) {
          // Copy width/height from component
          const width = this.getAttribute('width') || this.style.width || '100%'
          const height = this.getAttribute('height') || this.style.height || '100%'
          svg.setAttribute('width', width)
          svg.setAttribute('height', height)
        }
      }
    }
  )
}
