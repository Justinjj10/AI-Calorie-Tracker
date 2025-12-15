//
//  ImagePicker.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import UIKit

/// UIKit wrapper for UIImagePickerController
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    var sourceType: UIImagePickerController.SourceType
    var onImageSelected: ((UIImage) -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // Check if source type is available
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            DispatchQueue.main.async {
                self.isPresented = false
            }
            return picker
        }
        
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            guard let image = info[.originalImage] as? UIImage else {
                DispatchQueue.main.async {
                    self.parent.isPresented = false
                }
                return
            }
            
            // Set image first on main thread
            DispatchQueue.main.async {
                // Set image - this triggers the binding which updates the view model
                self.parent.selectedImage = image
                
                // Also call the callback if provided (for direct view model update)
                self.parent.onImageSelected?(image)
                
                // Dismiss after a brief delay to ensure view updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.parent.isPresented = false
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            DispatchQueue.main.async {
                self.parent.isPresented = false
            }
        }
    }
}
