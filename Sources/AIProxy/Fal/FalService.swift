//
//  FalService.swift
//
//
//  Created by Lou Zell on 9/13/24.
//

import Foundation

public final class FalService {
    private let partialKey: String
    private let serviceURL: String
    private let clientID: String?

    /// Creates an instance of FalService. Note that the initializer is not public.
    /// Customers are expected to use the factory `AIProxy.falService` defined in AIProxy.swift
    internal init(partialKey: String, serviceURL: String, clientID: String?) {
        self.partialKey = partialKey
        self.serviceURL = serviceURL
        self.clientID = clientID
    }

    /// Convenience method for creating a `fal-ai/fast-sdxl` image.
    ///
    /// - Parameter input: The input schema. See `FalFastSDXLInputSchema.swift` for the range of controls that you
    ///                    can use to adjust the image generation.
    ///
    /// - Returns: The inference result. The `images` property of the returned value contains a list of
    ///            generated images. Each image has a `url` that you can use to fetch the image contents
    ///            (or use with AsyncImage)
    public func createFastSDXLImage(
        input: FalFastSDXLInputSchema
    ) async throws -> FalFastSDXLOutputSchema {
        let queueResponse = try await self.createInference(
            model: "fal-ai/fast-sdxl",
            input: input
        )
        guard let statusURL = queueResponse.statusURL else {
            throw FalError.missingStatusURL
        }
        let completedResponse = try await self.pollForInferenceComplete(statusURL: statusURL)

        guard let responseURL = completedResponse.responseURL else {
            throw FalError.missingResultURL
        }
        return try await self.getResponse(url: responseURL)
    }

    /// If one of the convenience methods above does not fit your use case, you can use the
    /// following set of public methods.
    ///
    /// Look at the body of a convenience method above to model your own implementation off.
    /// You will need to create an inference, get the status URL from the returned object, poll
    /// the status URL, and when the status object returns `.completed` fetch the response URL.
    /// You can do it!
    ///
    /// Creates an inference on Fal. The returned value contains a URL that you can check for
    /// the status of your inference.
    public func createInference<T: Encodable>(
        model: String,
        input: T
    ) async throws -> FalQueueResponseBody {
        var model = model
        if !model.starts(with: "/") {
            model = "/" + model
        }
        let request = try await AIProxyURLRequest.create(
            partialKey: self.partialKey,
            serviceURL: self.serviceURL,
            clientID: self.clientID,
            proxyPath: model,
            body: input.serialize(),
            verb: .post,
            contentType: "application/json"
        )
        let (data, httpResponse) = try await BackgroundNetworker.send(request: request)
        if (httpResponse.statusCode > 299) {
            throw AIProxyError.unsuccessfulRequest(
                statusCode: httpResponse.statusCode,
                responseBody: String(data: data, encoding: .utf8) ?? ""
            )
        }
        return try FalQueueResponseBody.deserialize(from: data)
    }

    /// Polls for the completion of a model inference, where the polling URL is Fal's
    /// `status_url` described here: https://fal.ai/docs/model-endpoints/queue
    ///
    /// - Parameters:
    ///   - statusURL: The status URL returned from the `createInference` method
    ///   - pollAttempts: The number of times to poll before `FalError.reachedRetryLimit` is raised
    ///   - secondsBetweenPollAttempts: The number of seconds between polls
    ///
    /// - Returns: A queue response with the status of `.completed`
    public func pollForInferenceComplete(
        statusURL: URL,
        pollAttempts: Int = 30,
        secondsBetweenPollAttempts: UInt64 = 1
    ) async throws -> FalQueueResponseBody {
        return try await self.actorPollForInferenceCompletion(
            url: statusURL,
            numTries: pollAttempts,
            nsBetweenPollAttempts: secondsBetweenPollAttempts * 1_000_000_000
        )
    }

    /// Gets the response object from a completed inference. The URL to pass is the
    /// `response_url` described here: https://fal.ai/docs/model-endpoints/queue
    ///
    /// You should only call this method once `pollForInferenceComplete` returns.
    ///
    /// - Parameter url: The `responseURL` that is returned as part of `FalQueueResponseBody`
    ///
    /// - Returns: A decodable type that you define to match your model's "output schema". To find the
    ///            output schema, navigate to the model on Fal, then tap on "API" and scroll down until
    ///            you find the "Output" section. Here is an example:
    ///            https://fal.ai/models/fal-ai/fast-sdxl/api#schema-output
    public func getResponse<T: Decodable>(
        url: URL
    ) async throws -> T {
        guard url.host == "queue.fal.run" else {
            throw AIProxyError.assertion("Fal has changed the image polling domain")
        }
        let request = try await AIProxyURLRequest.create(
            partialKey: self.partialKey,
            serviceURL: self.serviceURL,
            clientID: self.clientID,
            proxyPath: url.path,
            body: nil,
            verb: .get
        )

        let (data, httpResponse) = try await BackgroundNetworker.send(request: request)

        if (httpResponse.statusCode > 299) {
            throw AIProxyError.unsuccessfulRequest(
                statusCode: httpResponse.statusCode,
                responseBody: String(data: data, encoding: .utf8) ?? ""
            )
        }

        return try T.deserialize(from: data)
    }

    @NetworkActor
    private func actorPollForInferenceCompletion(
        url: URL,
        numTries: Int,
        nsBetweenPollAttempts: UInt64
    ) async throws -> FalQueueResponseBody {
        try await Task.sleep(nanoseconds: nsBetweenPollAttempts)
        for _ in 0..<numTries {
            let response = try await self.actorGetStatus(
                url: url
            )
            switch response.status {
            case .inQueue, .inProgress, .none:
                try await Task.sleep(nanoseconds: nsBetweenPollAttempts)
            case .completed:
                return response
            }
        }
        throw FalError.reachedRetryLimit
    }

    @NetworkActor
    private func actorGetStatus(
        url: URL
    ) async throws -> FalQueueResponseBody {
        guard url.host == "queue.fal.run" else {
            throw AIProxyError.assertion("Fal has changed the image polling domain")
        }
        let request = try await AIProxyURLRequest.create(
            partialKey: self.partialKey,
            serviceURL: self.serviceURL,
            clientID: self.clientID,
            proxyPath: url.path,
            body: nil,
            verb: .get
        )

        let (data, httpResponse) = try await BackgroundNetworker.send(request: request)

        if (httpResponse.statusCode > 299) {
            throw AIProxyError.unsuccessfulRequest(
                statusCode: httpResponse.statusCode,
                responseBody: String(data: data, encoding: .utf8) ?? ""
            )
        }

        return try FalQueueResponseBody.deserialize(from: data)
    }
}
