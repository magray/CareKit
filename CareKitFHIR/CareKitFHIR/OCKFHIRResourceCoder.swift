/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CareKitStore
import Foundation
import ModelsDSTU2

/// Describes a type that is capable of encoding and decoding a CareKit entity
/// to and from a specific FHIR resource for specific FHIR release.
public protocol OCKFHIRResourceCoder {

    /// The CareKit entity that this coder encodes and decodes to and from.
    associatedtype Entity

    /// The FHIR resource that this coder converts to and from a CareKit entity.
    associatedtype Resource: OCKFHIRResource

    /// Converts a CareKit entity into a  FHIR resource.
    ///
    /// Conversion may fail if the entity cannot be fully expressed in the FHIR format.
    ///
    /// - Parameter entity: The CareKit entity to be converted.
    /// - Throws: `OCKFHIRCodingError`
    func convert(entity: Entity) throws -> Resource

    /// Converts a FHIR resource into a CareKit entity.
    ///
    /// Conversion may fail if the resource is missing fields that are required
    /// to instantiate its CareKit counterpart.
    ///
    /// - Parameter resource: The FHIR resource to be converted.
    /// - Throws: `OCKFHIRCodingError`
    func convert(resource: Resource) throws -> Entity
}

public extension OCKFHIRResourceCoder {

    /// Decode a CareKit entity from FHIR resource data.
    ///
    /// - Parameter resourceData: A FHIR resource from a specific release
    /// - Returns: A CareKit entity
    func decode<C: FHIRContentType>(_ resourceData: OCKFHIRResourceData<Resource.Release, C>) throws -> Entity {
        do {
            let resource = try Resource.decode(data: resourceData.data, contentType: C.self)
            let entity = try convert(resource: resource)
            return entity

        } catch {
            switch error {
            case let conversionError as OCKFHIRCodingError:
                throw conversionError.prependMessage("Failed to convert FHIR \(Resource.self) to \(Entity.self). Error:")
            case is DecodingError:
                throw OCKFHIRCodingError.corruptData("Failed to decode FHIR \(Resource.self) data. Error: \(error.localizedDescription)")
            default:
                throw OCKFHIRCodingError.unknownError(
                    "Unknown error while converting FHIR FHIR \(Resource.self) to \(Entity.self). Error: \(error.localizedDescription)"
                )
            }
        }
    }

    /// Encode a CareKit entity in a FHIR compatible format.
    ///
    /// - Parameters:
    ///   - entity: The CareKit entity to encode
    ///   - format: The FHIR content type to encode it in (JSON, XML, or Turtle). Defaults to JSON.
    /// - Returns: Binary data in a FHIR compatible format
    func encode(_ entity: Entity, format: FHIRContentType.Type = JSON.self) throws -> Data {
        let resource = try convert(entity: entity)
        let data = try resource.encode(to: format)
        return data
    }
}
