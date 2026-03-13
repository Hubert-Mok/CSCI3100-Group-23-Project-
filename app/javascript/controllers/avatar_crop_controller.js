import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

export default class extends Controller {
  static targets = ["triggerInput", "hiddenInput", "modal", "cropImage", "previewWrap"]

  cropper = null

  openPicker() {
    this.triggerInputTarget.click()
  }

  onFileChange(event) {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.cropImageTarget.src = e.target.result
      this.modalTarget.style.display = "flex"

      // Destroy any existing cropper before creating a new one
      if (this.cropper) {
        this.cropper.destroy()
        this.cropper = null
      }

      this.cropper = new Cropper(this.cropImageTarget, {
        aspectRatio: 1,
        viewMode: 1,
        dragMode: "move",
        autoCropArea: 0.8,
        restore: false,
        guides: false,
        center: true,
        highlight: false,
        cropBoxMovable: true,
        cropBoxResizable: true,
        toggleDragModeOnDblclick: false,
      })
    }
    reader.readAsDataURL(file)
  }

  cropAndSave() {
    if (!this.cropper) return

    this.cropper.getCroppedCanvas({ width: 400, height: 400 }).toBlob((blob) => {
      const file = new File([blob], "avatar.jpg", { type: "image/jpeg" })
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(file)
      this.hiddenInputTarget.files = dataTransfer.files

      // Update the preview
      const url = URL.createObjectURL(blob)
      this.previewWrapTarget.innerHTML =
        `<img src="${url}" class="avatar-upload-current" alt="New avatar">`

      this._closeModal()
    }, "image/jpeg", 0.92)
  }

  cancel() {
    this._closeModal()
    this.triggerInputTarget.value = ""
  }

  _closeModal() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
    this.modalTarget.style.display = "none"
    this.cropImageTarget.src = ""
  }
}
