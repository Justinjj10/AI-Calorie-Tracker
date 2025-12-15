//
//  ImageServiceTests.swift
//  AI-Calorie-TrackerTests
//
//  Created by Justin Joseph on 12/15/25.
//

import Testing
import UIKit
@testable import AI_Calorie_Tracker

struct ImageServiceTests {
    @Test func compressImageRespectsMaxSize() throws {
        let image = TestHelper.makeSolidImage(size: CGSize(width: 800, height: 800))
        let data = ImageService.shared.compressImage(image)
        
        #expect(data != nil)
        #expect((data?.count ?? 0) <= Config.maxImageSize)
    }
    
    @Test func imageToBase64ProducesString() throws {
        let image = TestHelper.makeSolidImage(size: CGSize(width: 200, height: 200))
        let base64 = ImageService.shared.imageToBase64(image)
        
        #expect(base64?.isEmpty == false)
    }
}

