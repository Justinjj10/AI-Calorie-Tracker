//
//  CameraView.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import AVFoundation
import CoreData

/// View for capturing and selecting food photos
struct CameraView: View {
    @State private var showCameraPicker = false
    @State private var showPhotoPicker = false
    @State private var cameraDeniedAlert = false
    @State private var showAnalysisView = false
    @State private var showErrorAlert = false
    @State private var analysisTask: Task<Void, Never>?
    
    @StateObject private var cameraViewModel = CameraViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var analysisViewModel: FoodAnalysisViewModel = {
        let context = PersistenceController.shared.container.viewContext
        let persistenceService = PersistenceService(viewContext: context)
        return FoodAnalysisViewModel(persistenceService: persistenceService)
    }()
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Food Tracker")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if cameraViewModel.selectedImage != nil {
                            Button("Clear") {
                                cameraViewModel.clearImage()
                                analysisViewModel.clearAnalysis()
                            }
                        }
                    }
                }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(
                selectedImage: $cameraViewModel.selectedImage,
                isPresented: $showPhotoPicker,
                sourceType: .photoLibrary,
                onImageSelected: { image in
                    cameraViewModel.didSelectImage(image)
                }
            )
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(
                selectedImage: $cameraViewModel.selectedImage,
                isPresented: $showCameraPicker,
                sourceType: .camera,
                onImageSelected: { image in
                    cameraViewModel.didSelectImage(image)
                }
            )
        }
        .sheet(isPresented: $showAnalysisView) {
            if analysisViewModel.analysis != nil {
                FoodAnalysisView(
                    analysisViewModel: analysisViewModel,
                    cameraViewModel: cameraViewModel
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {
                cameraViewModel.errorMessage = nil
                analysisViewModel.errorMessage = nil
            }
        } message: {
            if let error = cameraViewModel.errorMessage {
                Text(error)
            } else if let error = analysisViewModel.errorMessage {
                Text(error)
            }
        }
        .alert("Camera Access Needed", isPresented: $cameraDeniedAlert) {
            Button("OK", role: .cancel) {}
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please allow camera access in Settings to take photos.")
        }
        .onChange(of: cameraViewModel.errorMessage) { _, newValue in
            showErrorAlert = newValue != nil
        }
        .onChange(of: analysisViewModel.errorMessage) { _, newValue in
            showErrorAlert = newValue != nil
        }
        .onDisappear {
            analysisTask?.cancel()
            analysisTask = nil
        }
    }
    
    private var mainContent: some View {
        ZStack {
            if let image = cameraViewModel.selectedImage {
                imagePreviewView(image: image)
            } else {
                cameraSelectionView
            }
        }
    }
    
    private func imagePreviewView(image: UIImage) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Image Preview Card
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 400)
                        .clipped()
                        .cornerRadius(20)
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 16) {
                    analyzeButton
                    
                    Button(action: {
                        cameraViewModel.clearImage()
                        analysisViewModel.clearAnalysis()
                        showAnalysisView = false
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Take Another Photo")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
    }
    
    private var analyzeButton: some View {
        Button(action: {
            analyzeImage()
        }) {
            HStack(spacing: 12) {
                if !cameraViewModel.isLoading && !analysisViewModel.isLoading {
                    Image(systemName: "sparkles")
                        .font(.title3)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(cameraViewModel.isLoading || analysisViewModel.isLoading ? "Analyzing..." : "Analyze Food")
                    .fontWeight(.semibold)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: (cameraViewModel.isLoading || analysisViewModel.isLoading) ? [Color.gray, Color.gray.opacity(0.8)] : [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: (cameraViewModel.isLoading || analysisViewModel.isLoading) ? Color.clear : Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(cameraViewModel.isLoading || analysisViewModel.isLoading)
        .padding(.horizontal)
    }
    
    private var cameraSelectionView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 12) {
                Text("Capture Your Food")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Take a photo or select from your library to analyze calories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            cameraButtons
            
            Spacer()
        }
        .padding()
    }
    
    private var cameraButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                Task { await requestAndPresentCamera() }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.title3)
                    Text("Camera")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }

            Button(action: {
                showPhotoPicker = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                    Text("Library")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.horizontal, 40)
    }
    
    private func requestAndPresentCamera() async {
        switch await AVCaptureDevice.requestAccess(for: .video) {
        case true:
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                showCameraPicker = true
            } else {
                cameraViewModel.errorMessage = "Camera not available on this device."
            }
        case false:
            cameraDeniedAlert = true
        }
    }

    private func analyzeImage() {
        guard let base64Image = cameraViewModel.getBase64Image() else {
            cameraViewModel.errorMessage = "Failed to process image"
            return
        }
        
        // Cancel any existing analysis task
        analysisTask?.cancel()
        
        cameraViewModel.isLoading = true
        
        analysisTask = Task { @MainActor in
            // Check for cancellation
            guard !Task.isCancelled else {
                cameraViewModel.isLoading = false
                return
            }
            
            // Perform actual analysis
            await analysisViewModel.analyzeImage(imageBase64: base64Image)
            
            // Check for cancellation after API call
            guard !Task.isCancelled else {
                cameraViewModel.isLoading = false
                return
            }
            
            cameraViewModel.isLoading = false
            
            if analysisViewModel.analysis != nil {
                showAnalysisView = true
            } else if let error = analysisViewModel.errorMessage {
                cameraViewModel.errorMessage = error
            }
        }
    }
}

#Preview {
    CameraView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

