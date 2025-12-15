//
//  ImageProcessingProtocol.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import Foundation
import UIKit

/// Protocol for image processing operations
protocol ImageProcessingProtocol {
    /// Compress image to target size
    func compressImage(_ image: UIImage, targetSize: Int, maxSize: Int) -> Data?
    
    /// Convert image to base64 string
    func imageToBase64(_ image: UIImage) -> String?
    
    /// Create thumbnail from image data
    func createThumbnail(from imageData: Data, maxDimension: CGFloat) -> UIImage?
}

