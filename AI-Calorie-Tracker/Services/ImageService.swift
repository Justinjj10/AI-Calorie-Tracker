//
//  ImageService.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import UIKit
import Foundation

/// Service for image compression and processing
class ImageService: ImageProcessingProtocol {
    static let shared = ImageService()
    
    // MARK: - Constants
    private enum Constants {
        static let defaultQuality: CGFloat = 0.7
        static let maxIterations = 10
        static let qualityTolerance: CGFloat = 0.05
    }
    
    private init() {}
    
    /// Compress image to target size while maintaining quality
    /// - Parameters:
    ///   - image: UIImage to compress
    ///   - targetSize: Target size in bytes (default: 4MB)
    ///   - maxSize: Maximum size in bytes (default: 20MB)
    /// - Returns: Compressed image data as JPEG
    func compressImage(_ image: UIImage, targetSize: Int = Config.targetImageSize, maxSize: Int = Config.maxImageSize) -> Data? {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return nil
        }
        
        // If already under target size, return as is
        if imageData.count <= targetSize {
            return imageData
        }
        
        // If over max size, we need to resize first
        var currentImage = image
        if imageData.count > maxSize {
            // Calculate scale factor to get under max size
            let scaleFactor = sqrt(Double(maxSize) / Double(imageData.count))
            let newSize = CGSize(
                width: image.size.width * scaleFactor,
                height: image.size.height * scaleFactor
            )
            
            guard let resizedImage = resizeImage(image, to: newSize) else {
                return nil
            }
            currentImage = resizedImage
        }
        
        // Binary search for optimal compression quality
        return findOptimalCompression(image: currentImage, targetSize: targetSize) 
            ?? currentImage.jpegData(compressionQuality: Constants.defaultQuality)
    }
    
    /// Find optimal compression quality using binary search
    /// - Parameters:
    ///   - image: Image to compress
    ///   - targetSize: Target size in bytes
    /// - Returns: Compressed image data
    private func findOptimalCompression(image: UIImage, targetSize: Int) -> Data? {
        var low: CGFloat = 0.0
        var high: CGFloat = 1.0
        var bestData: Data?
        
        for _ in 0..<Constants.maxIterations {
            let quality = (low + high) / 2.0
            guard let compressedData = image.jpegData(compressionQuality: quality) else {
                break
            }
            
            if compressedData.count <= targetSize {
                bestData = compressedData
                high = quality
            } else {
                low = quality
            }
            
            // If we're close enough, break
            if abs(high - low) < Constants.qualityTolerance {
                break
            }
        }
        
        return bestData
    }
    
    /// Resize image to specified size
    /// - Parameters:
    ///   - image: UIImage to resize
    ///   - size: Target size
    /// - Returns: Resized UIImage
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Convert image to base64 string for API
    /// - Parameter image: UIImage to convert
    /// - Returns: Base64 encoded string
    func imageToBase64(_ image: UIImage) -> String? {
        guard let imageData = compressImage(image) else {
            return nil
        }
        return imageData.base64EncodedString()
    }
    
    /// Create thumbnail from image data
    /// - Parameters:
    ///   - imageData: Image data
    ///   - maxDimension: Maximum dimension for thumbnail (default: 200)
    /// - Returns: Thumbnail UIImage
    func createThumbnail(from imageData: Data, maxDimension: CGFloat = 200) -> UIImage? {
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        
        let thumbnailSize = calculateThumbnailSize(for: image.size, maxDimension: maxDimension)
        return resizeImage(image, to: thumbnailSize)
    }
    
    /// Calculate thumbnail size maintaining aspect ratio
    /// - Parameters:
    ///   - originalSize: Original image size
    ///   - maxDimension: Maximum dimension for thumbnail
    /// - Returns: Calculated thumbnail size
    private func calculateThumbnailSize(for originalSize: CGSize, maxDimension: CGFloat) -> CGSize {
        let aspectRatio = originalSize.width / originalSize.height
        
        if originalSize.width > originalSize.height {
            return CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            return CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
    }
}

