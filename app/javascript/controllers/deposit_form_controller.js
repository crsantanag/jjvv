// app/javascript/controllers/deposit_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dateFields", "mes", "ano", "amountInput"]

  connect() {
    this.setupTipoIngresoListener()
    this.formatAmountInput()
  }

  setupTipoIngresoListener() {
    const radios = document.querySelectorAll("input[name='deposit[tipo_ingreso]']")

    radios.forEach(radio => {
      radio.addEventListener("change", () => this.toggleDateFields())
    })

    this.toggleDateFields() // inicial
  }
 
  toggleDateFields() {
    const selected = document.querySelector("input[name='deposit[tipo_ingreso]']:checked")?.value
    const isComun = selected === "ingreso_comun"

    this.dateFieldsTarget.style.display = isComun ? "block" : "none"
    this.mesTarget.required = isComun
    this.anoTarget.required = isComun
  }

  formatAmountInput() {
    if (!this.hasAmountInputTarget) return

    const input = this.amountInputTarget
    const rawValue = input.value.replace(/\D/g, "")
    input.dataset.originalValue = rawValue
    input.value = this.formatCLP(rawValue)

    input.addEventListener("input", () => {
      const raw = input.value.replace(/\D/g, "")
      input.dataset.originalValue = raw
      input.value = this.formatCLP(raw)
    })

    input.form?.addEventListener("submit", () => {
      input.value = input.dataset.originalValue
    })
  }

  formatCLP(value) {
    return new Intl.NumberFormat("es-CL", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(value)
  }
}
