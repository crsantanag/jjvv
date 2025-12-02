import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "search", "label"]

  connect() {
    this.radioTargets.forEach(radio => {
      radio.addEventListener("change", (event) => {
        const selectedValue = event.target.value

        // Cambiar el texto del label
        if (this.hasLabelTarget) {
          this.labelTarget.innerText =
            selectedValue === "description"
              ? "Buscar por nombre de socio:"
              : "Buscar por número de socio:"
        }

        // Limpiar el campo de búsqueda
        if (this.hasSearchTarget) {
          this.searchTarget.value = ""
        }

        // Enviar el formulario
        this.element.requestSubmit()
      })
    })
  }
}


