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

    @StateObject private var cameraViewModel = CameraViewModel()
    @StateObject private var analysisViewModel: FoodAnalysisViewModel = {
        let context = PersistenceController.shared.container.viewContext
        let persistenceService = PersistenceService(viewContext: context)
        return FoodAnalysisViewModel(persistenceService: persistenceService)
    }()
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showAnalysisView = false
    @State private var showErrorAlert = false
    @State private var refreshID = UUID() // Force view refresh
    @State private var analysisProgress: Double = 0.0
    @State private var showAnalysisOverlay = false
    @State private var analysisTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Food Tracker")
                .preferredColorScheme(.light) // Force light mode
                .modifier(CameraViewModifiers(
                    cameraViewModel: cameraViewModel,
                    analysisViewModel: analysisViewModel,
                    showPhotoPicker: $showPhotoPicker,
                    showCameraPicker: $showCameraPicker,
                    showAnalysisView: $showAnalysisView,
                    showErrorAlert: $showErrorAlert,
                    cameraDeniedAlert: $cameraDeniedAlert,
                    requestAndPresentCamera: requestAndPresentCamera,
                    onImageSet: {
                        // Force view refresh when image is set
                        refreshID = UUID()
                    }
                ))
                .onDisappear {
                    // Cancel analysis task when view disappears
                    analysisTask?.cancel()
                    analysisTask = nil
                }
        }
    }
    
    private var mainContent: some View {
        ZStack {
            if let image = cameraViewModel.selectedImage {
                imagePreviewView(image: image)
                    .id(refreshID) // Force view update when refreshID changes
            } else {
                cameraSelectionView
            }
        }
        .id(refreshID) // Also add ID to the ZStack to force refresh
    }
    
    private func imagePreviewView(image: UIImage) -> some View {
        ZStack {
            VStack(spacing: 24) {
                // Image Preview Card
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .clipped()
                        .cornerRadius(20)
                }
                .frame(height: 400)
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 16) {
                    analyzeButton
                    
                    Button(action: {
                        // Clear image, analysis, and close analysis view
                        cameraViewModel.clearImage()
                        analysisViewModel.clearAnalysis()
                        showAnalysisView = false
                        showAnalysisOverlay = false
                        analysisProgress = 0
                        // Force view refresh
                        refreshID = UUID()
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Cancel")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                    .padding(.horizontal)
                }
            }
            
            // Analysis Overlay
            if showAnalysisOverlay {
                analysisOverlay
            }
        }
    }
    
    private var analyzeButton: some View {
        Button(action: {
            analyzeImage()
        }) {
            HStack(spacing: 12) {
                if !cameraViewModel.isLoading {
                    Image(systemName: "sparkles")
                        .font(.title3)
                }
                Text(cameraViewModel.isLoading ? "Analyzing..." : "Analyze Food")
                    .fontWeight(.semibold)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: cameraViewModel.isLoading ? [Color.gray, Color.gray.opacity(0.8)] : [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: cameraViewModel.isLoading ? Color.clear : Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(cameraViewModel.isLoading)
        .padding(.horizontal)
    }
    
    private var analysisOverlay: some View {
        ZStack {
            // Blur background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Circular Progress Indicator
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 12)
                        .frame(width: 180, height: 180)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: analysisProgress)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: analysisProgress)
                    
                    // Percentage and icon
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .symbolEffect(.pulse, options: .repeating)
                        
                        Text("\(Int(analysisProgress * 100))%")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Analyzing...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Animated dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .scaleEffect(analysisProgress > 0 ? 1 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: analysisProgress
                            )
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .scale))
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
        showAnalysisOverlay = true
        analysisProgress = 0
        
        analysisTask = Task { @MainActor in
            // Check for cancellation
            guard !Task.isCancelled else { return }
            // Start progress animation
            withAnimation(.linear(duration: 0.1)) {
                analysisProgress = 0.1
            }
            
            // Simulate progress updates
            for progress in stride(from: 0.1, through: 0.9, by: 0.1) {
                // Check for cancellation
                if Task.isCancelled {
                    cameraViewModel.isLoading = false
                    showAnalysisOverlay = false
                    return
                }
                
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                
                // Check again after sleep
                if Task.isCancelled {
                    cameraViewModel.isLoading = false
                    showAnalysisOverlay = false
                    return
                }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    analysisProgress = progress
                }
            }
            
            // Check for cancellation before API call
            guard !Task.isCancelled else {
                cameraViewModel.isLoading = false
                showAnalysisOverlay = false
                return
            }
            
            // Perform actual analysis
            await analysisViewModel.analyzeImage(imageBase64: base64Image)
            
            // Check for cancellation after API call
            guard !Task.isCancelled else {
                cameraViewModel.isLoading = false
                showAnalysisOverlay = false
                return
            }
            
            // Complete progress
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                analysisProgress = 1.0
            }
            
            // Small delay to show completion
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Final cancellation check
            guard !Task.isCancelled else {
                cameraViewModel.isLoading = false
                showAnalysisOverlay = false
                return
            }
            
            cameraViewModel.isLoading = false
            showAnalysisOverlay = false
            analysisProgress = 0
            
            if analysisViewModel.analysis != nil {
                showAnalysisView = true
            } else if let error = analysisViewModel.errorMessage {
                cameraViewModel.errorMessage = error
            }
        }
    }
}

// MARK: - View Modifiers
private struct CameraViewModifiers: ViewModifier {
    let cameraViewModel: CameraViewModel
    let analysisViewModel: FoodAnalysisViewModel
    @Binding var showPhotoPicker: Bool
    @Binding var showCameraPicker: Bool
    @Binding var showAnalysisView: Bool
    @Binding var showErrorAlert: Bool
    @Binding var cameraDeniedAlert: Bool
    let requestAndPresentCamera: () async -> Void
    let onImageSet: () -> Void
    
    func body(content: Content) -> some View {
        let showActionSheetBinding = Binding(
            get: { cameraViewModel.showActionSheet },
            set: { cameraViewModel.showActionSheet = $0 }
        )
        
        _ = Binding(
            get: { cameraViewModel.showImagePicker },
            set: { cameraViewModel.showImagePicker = $0 }
        )
        
        let selectedImageBinding = Binding(
            get: { cameraViewModel.selectedImage },
            set: { newValue in
                // Direct assignment - @Published will handle the update
                // CameraViewModel is @MainActor so this is already on main thread
                cameraViewModel.selectedImage = newValue
                // Call callback to force view refresh
                if newValue != nil {
                    onImageSet()
                }
            }
        )
        
        let withDialogs = content
            .confirmationDialog("Select Photo Source", isPresented: showActionSheetBinding, titleVisibility: .visible) {
                confirmationDialogContent
            }
        
        let withSheets = withDialogs
            .sheet(isPresented: $showPhotoPicker) {
                ImagePicker(
                    selectedImage: selectedImageBinding,
                    isPresented: $showPhotoPicker,
                    sourceType: .photoLibrary,
                    onImageSelected: { image in
                        // Direct update to ensure view refreshes
                        cameraViewModel.selectedImage = image
                        onImageSet()
                    }
                )
            }
            .sheet(isPresented: $showCameraPicker) {
                ImagePicker(
                    selectedImage: selectedImageBinding,
                    isPresented: $showCameraPicker,
                    sourceType: .camera,
                    onImageSelected: { image in
                        // Direct update to ensure view refreshes
                        cameraViewModel.selectedImage = image
                        onImageSet()
                    }
                )
            }
            .sheet(isPresented: $showAnalysisView) {
                analysisSheetContent
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        
        let withAlerts = withSheets
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {
                    cameraViewModel.errorMessage = nil
                }
            } message: {
                if let error = cameraViewModel.errorMessage {
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
        
        return withAlerts
            .onChange(of: cameraViewModel.errorMessage) { _, newValue in
                showErrorAlert = newValue != nil
            }
            .onChange(of: cameraViewModel.selectedImage) { oldValue, newValue in
                // Explicitly observe image changes to ensure view updates
                // This helps debug if the binding is working
                if newValue != nil {
                    // Image was set - view should update automatically via @StateObject
                }
            }
    }
    
    private var confirmationDialogContent: some View {
        Group {
            if cameraViewModel.isCameraAvailable {
                Button("Camera") {
                    Task { await requestAndPresentCamera() }
                }
            }
            if cameraViewModel.isPhotoLibraryAvailable {
                Button("Photo Library") {
                    showPhotoPicker = true
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    @ViewBuilder
    private var analysisSheetContent: some View {
        if analysisViewModel.analysis != nil {
            FoodAnalysisView(
                analysisViewModel: analysisViewModel,
                cameraViewModel: cameraViewModel
            )
        }
    }
}

#Preview {
    CameraView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

