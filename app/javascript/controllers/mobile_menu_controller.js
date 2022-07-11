import { Controller } from "@hotwired/stimulus"

const CLOSED = "closed"
const OPEN = "open"

export default class extends Controller {
  static targets = [ "wrapper", "revealable"]
  static classes = [ "hidden" ] // necessary because we're always hiding the mobile menu on larger screens and this is the class used for only mobile screen sizes
  static values = {
    showEventName: String,
    hideEventName: String,
  }
  
  connect() {
    this.addDefaultStatusPropertyToRevealableTargets()
  }
  
  dispatchEventToRevealableTargets(eventName) {
    console.log('dispatchEventToRevealableTargets', eventName)
    this.revealableTargets.forEach((revealableTarget) => revealableTarget.dispatchEvent(new CustomEvent(eventName)))
  }

  toggle() {
    if (this.areAllRevealableTargetsOfStatus(CLOSED)) {
      this.open()
    } else if (this.areAllRevealableTargetsOfStatus(OPEN)){
      this.close()
    }
    // else it's transitioning so ignore
  }
  
  open() {
    this.setStatusOfRevealableTargetsTo(CLOSED)
    this.showWrapper()
    this.dispatchEventToRevealableTargets(this.showEventNameValue)
  }
  
  finishOpening(event) {
    console.log('finishOpening', event.type, event.target, event.currentTarget)
    event.currentTarget.dataset.mobileMenuRevealableTargetStatus = OPEN
  }
  
  close() {
    this.setStatusOfRevealableTargetsTo(OPEN)
    this.dispatchEventToRevealableTargets(this.hideEventNameValue)
  }
  
  finishClosing() {
    event.currentTarget.dataset.mobileMenuRevealableTargetStatus = CLOSED
    console.log('finishClosing', event.type, event.currentTarget.dataset.mobileMenuRevealableTargetStatus, this.areAllRevealableTargetsOfStatus(CLOSED))
    if (this.areAllRevealableTargetsOfStatus(CLOSED)) {
      this.hideWrapper()
    }
  }
  
  addDefaultStatusPropertyToRevealableTargets() {
    if (!this.areAllRevealableTargetsOfStatus(CLOSED) && !this.areAllRevealableTargetsOfStatus(OPEN)) {
      this.setStatusOfRevealableTargetsTo(CLOSED)
    }
  }
  
  setStatusOfRevealableTargetsTo(status) {
    this.revealableTargets.forEach((revealableTarget) => revealableTarget.dataset.mobileMenuRevealableTargetStatus = status)
  }
  
  areAllRevealableTargetsOfStatus(status) {
    return this.revealableTargets.length === this.revealableTargets.filter((revealableTarget) => revealableTarget.dataset.mobileMenuRevealableTargetStatus === status).length
  }
  
  showWrapper() {
    this.wrapperTarget.classList.remove(this.hiddenClass)
  }
  
  hideWrapper() {
    this.wrapperTarget.classList.add(this.hiddenClass)
  }
}