// controllers/confirm_delete_modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["confirm", "modal"]

  showModal(event) {
    const button = event.currentTarget
    const formId = button.dataset.depositForm || button.dataset.billForm

    this.confirmTarget.dataset.formId = formId

    const modal = bootstrap.Modal.getOrCreateInstance(this.modalTarget)
    modal.show()
  }

  confirmDelete() {
    const formId = this.confirmTarget.dataset.formId
    const modal = bootstrap.Modal.getInstance(this.modalTarget)

    if (modal) {
      modal.hide()
    }

    if (formId) {
      setTimeout(() => {
        const form = document.getElementById(formId)
        if (form) {
          form.submit()
        }
      }, 300) // da tiempo para que se cierre el modal
    }
  }
}
