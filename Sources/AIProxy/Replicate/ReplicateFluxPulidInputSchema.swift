//
//  ReplicateFluxPulidInputSchema.swift
//  
//
//  Created by Lou Zell on 9/19/24.
//

import Foundation

/// Docstrings are from: https://replicate.com/zsxkib/flux-pulid/api/schema
public struct ReplicateFluxPulidInputSchema: Encodable {
    /// Upload an ID image for face generation
    public let mainFaceImage: URL

    /// Enter a text prompt to guide image generation
    public let prompt: String

    /// Set the guidance scale for text prompt influence (1.0-10.0)
    public let guidanceScale: Double?

    /// Set the height of the generated image (256-1536 pixels)
    public let height: Int?

    /// Set the weight of the ID image influence (0.0-3.0)
    public let idWeight: Double?

    /// Set the max sequence length for prompt (T5), smaller is faster (128-512)
    public let maxSequenceLength: Int?

    /// Enter a negative prompt to specify what to avoid in the image
    public let negativePrompt: String?

    /// Set the number of images to generate (1-4)
    public let numOutputs: Int?

    /// Set the number of denoising steps (1-20)
    public let numSteps: Int?

    /// Choose the format of the output image
    public let outputFormat: String?

    /// Set the quality of the output image for jpg and webp (1-100)
    public let outputQuality: Int?

    /// Set a random seed for generation (leave blank or -1 for random)
    public let seed: Int?

    /// Set the timestep to start inserting ID (0-4 recommended, 0 for highest fidelity, 4 for more editability)
    public let startStep: Int?

    /// Set the Classifier-Free Guidance (CFG) scale. 1.0 uses standard CFG, while values >1.0
    /// enable True CFG for more precise control over generation. Higher values increase adherence to
    /// the prompt at the cost of image quality.
    public let trueCFG: Double?

    /// Set the width of the generated image (256-1536 pixels)
    public let width: Int?

    private enum CodingKeys: String, CodingKey {
        case guidanceScale = "guidance_scale"
        case height
        case idWeight = "id_weight"
        case mainFaceImage = "main_face_image"
        case maxSequenceLength = "max_sequence_length"
        case negativePrompt = "negative_prompt"
        case numOutputs = "num_outputs"
        case numSteps = "num_steps"
        case outputFormat = "output_format"
        case outputQuality = "output_quality"
        case prompt
        case seed
        case startStep = "start_step"
        case trueCFG = "true_cfg"
        case width
    }

    // This memberwise initializer is autogenerated.
    // To regenerate, use `cmd-shift-a` > Generate Memberwise Initializer
    // To format, place the cursor in the initializer's parameter list and use `ctrl-m`
    public init(
        mainFaceImage: URL,
        prompt: String,
        guidanceScale: Double? = nil,
        height: Int? = nil,
        idWeight: Double? = nil,
        maxSequenceLength: Int? = nil,
        negativePrompt: String? = nil,
        numOutputs: Int? = nil,
        numSteps: Int? = nil,
        outputFormat: String? = nil,
        outputQuality: Int? = nil,
        seed: Int? = nil,
        startStep: Int? = nil,
        trueCFG: Double? = nil,
        width: Int? = nil
    ) {
        self.mainFaceImage = mainFaceImage
        self.prompt = prompt
        self.guidanceScale = guidanceScale
        self.height = height
        self.idWeight = idWeight
        self.maxSequenceLength = maxSequenceLength
        self.negativePrompt = negativePrompt
        self.numOutputs = numOutputs
        self.numSteps = numSteps
        self.outputFormat = outputFormat
        self.outputQuality = outputQuality
        self.seed = seed
        self.startStep = startStep
        self.trueCFG = trueCFG
        self.width = width
    }
}
