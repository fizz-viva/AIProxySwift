//
//  AnthropicService.swift
//
//
//  Created by Lou Zell on 7/25/24.
//

import Foundation

public final class AnthropicService {
    private let partialKey: String
    private let serviceURL: String
    private let clientID: String?

    /// Creates an instance of OpenAIService. Note that the initializer is not public.
    /// Customers are expected to use the factory `AIProxy.openAIService` defined in AIProxy.swift
    internal init(partialKey: String, serviceURL: String, clientID: String?) {
        self.partialKey = partialKey
        self.serviceURL = serviceURL
        self.clientID = clientID
    }

    /// Initiates a non-streaming request to /v1/messages.
    ///
    /// - Parameters:
    ///   - messageRequestBody: The request body to send to aiproxy and anthropic. See this reference:
    ///                         https://docs.anthropic.com/en/api/messages
    /// - Returns: The message response, See this reference:
    ///            https://platform.openai.com/docs/api-reference/chat/object
    public func messageRequest(
        body: AnthropicMessageRequestBody
    ) async throws -> AnthropicMessageResponseBody {
        var body = body
        body.stream = false
        let session = AIProxyURLSession.create()
        let request = try await AIProxyURLRequest.create(
            partialKey: self.partialKey,
            serviceURL: self.serviceURL,
            clientID: self.clientID,
            proxyPath: "/v1/messages",
            body: try body.serialize(),
            verb: .post,
            contentType: "application/json"
        )
        let (data, res) = try await session.data(for: request)
        guard let httpResponse = res as? HTTPURLResponse else {
            throw AIProxyError.assertion("Network response is not an http response")
        }

        if (httpResponse.statusCode > 299) {
            throw AIProxyError.unsuccessfulRequest(
                statusCode: httpResponse.statusCode,
                responseBody: String(data: data, encoding: .utf8) ?? ""
            )
        }
    
        return try AnthropicMessageResponseBody.deserialize(from: data)
    }
}
