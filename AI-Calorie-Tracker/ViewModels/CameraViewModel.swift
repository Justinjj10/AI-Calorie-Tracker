//
//  CameraViewModel.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import UIKit
import Combine
import AVFoundation

/// ViewModel for camera and image picker functionality
@MainActor
class CameraViewModel: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    @Published var selectedImage: UIImage?
    @Published var showImagePicker = false
    @Published var showCamera = false
    @Published var showActionSheet = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    /// Check if camera is available
    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    /// Check if photo library is available
    var isPhotoLibraryAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
    
    /// Present image picker source selection
    func presentImageSourceSelection() {
        showActionSheet = true
    }
    
    /// Request camera permission and show camera if available
    func requestCameraAccess() {
        guard isCameraAvailable else {
            errorMessage = "Camera is not available on this device"
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.showCamera = true
                    } else {
                        self?.errorMessage = "Camera access is required to take photos"
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = "Camera access is denied. Please enable it in Settings."
        @unknown default:
            errorMessage = "Unable to access camera"
        }
    }
    
    /// Handle image selection from picker
    /// - Parameter image: Selected UIImage
    func didSelectImage(_ image: UIImage) {
        selectedImage = image
        showImagePicker = false
        showCamera = false
    }
    
    /// Clear selected image
    func clearImage() {
        selectedImage = nil
    }
    
    /// Get compressed image data for API
    /// - Returns: Compressed image data
    func getCompressedImageData() -> Data? {
        guard let image = selectedImage else {
            return nil
        }
        return ImageService.shared.compressImage(image)
    }
    
    /// Get base64 encoded image for API
    /// - Returns: Base64 encoded string
    func getBase64Image() -> String? {
        guard let image = selectedImage else {
            return nil
        }
        return ImageService.shared.imageToBase64(image)
    }
}

