// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Carga automática de los demás controladores
eagerLoadControllersFrom("controllers", application)

// Registro manual de ConfirmDeleteModalController
import ConfirmDeleteModalController from "controllers/confirm_delete_modal_controller"
application.register("confirm-delete-modal", ConfirmDeleteModalController)
