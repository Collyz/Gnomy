//
//  Database.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 6/21/25.
//

import AWSDynamoDB
import Foundation

/// Represents the structure of a player item stored in DynamoDB.
struct PlayerDBInfo: Identifiable {
    let id: String
    var username: String
    var highscore: Int64
}

/// An enumeration of error codes representing issues that can arise when using
/// the `DynamoDBManager` class.
enum GnomyScoresError: Error {
    /// The specified table wasn't found or couldn't be created.
    case tableNotFound
    /// The specified item wasn't found or couldn't be created.
    case itemNotFound
    /// The Amazon DynamoDB client is not properly initialized.
    case uninitializedClient
    /// The table status reported by Amazon DynamoDB is not recognized.
    case unknownTableStatus
    /// One or more specified attribute values are invalid or missing.
    case invalidAttributes
}

class DynamoDBManager {
    private var ddbClient: DynamoDBClient?
    private let tableName: String = "GnomyScores"

    /// Create an object representing a player score table in an Amazon DynamoDB
    /// database.
    ///
    /// - Parameters:
    ///   - region: The optional Amazon Region to create the database in.
    ///
    /// > Note: The table is not necessarily available when this function
    /// returns. Use `tableExists()` to check for its availability, or
    /// `waitForTableActive()` to wait until the table's status is reported as
    /// ready to use by Amazon DynamoDB.
    init(region: String? = nil) async throws {
        do {
            let config = try await DynamoDBClient.DynamoDBClientConfiguration()
            if let region = region {
                config.region = region
            }

            self.ddbClient = DynamoDBClient(config: config)
        } catch {
            print("ERROR: ", dump(error, name: "Initializing Amazon DynamoDBClient client"))
            throw error
        }
    }

    /// Create the player score table in the Amazon DynamoDB data store.
    private func createTable() async throws {
        print("Creating the table...")
        do {
            guard let client = self.ddbClient else {
                throw GnomyScoresError.uninitializedClient
            }

            let input = CreateTableInput(
                attributeDefinitions: [
                    .init(attributeName: "playerID", attributeType: DynamoDBClientTypes.ScalarAttributeType.s),
                    .init(attributeName: "score", attributeType: DynamoDBClientTypes.ScalarAttributeType.n)
                ],
                billingMode: DynamoDBClientTypes.BillingMode.payPerRequest,
                globalSecondaryIndexes: [
                    .init(
                        indexName: "ScoreIndex",
                        keySchema: [
                            .init(attributeName: "score", keyType: DynamoDBClientTypes.KeyType.hash) // or .range if sorting is required
                        ],
                        projection: .init(projectionType: DynamoDBClientTypes.ProjectionType.all)
                    )
                ],
                keySchema: [
                    .init(attributeName: "playerID", keyType: DynamoDBClientTypes.KeyType.hash)
                ],
                
                tableName: tableName
            )

            let output = try await client.createTable(input: input)
            if output.tableDescription == nil {
                throw GnomyScoresError.tableNotFound
            }
        } catch {
            print("ERROR: createTable:", dump(error))
            throw error
        }
    }

    /// Check if the table already exists in DynamoDB and is active.
    private func tableExists() async throws -> Bool {
        guard let client = ddbClient else {
            throw GnomyScoresError.uninitializedClient
        }

        let input = DescribeTableInput(tableName: tableName)
        let output = try await client.describeTable(input: input)
        return output.table?.tableStatus == .active
    }
    
    /// Inserts or updates a player's info in the DynamoDB table.
    func insertPlayer(playerID: String, username: String, score: Int64) async throws {
        guard let client = ddbClient else {
            throw GnomyScoresError.uninitializedClient
        }

        let item: [String: DynamoDBClientTypes.AttributeValue] = [
            "playerID": .s(playerID),
            "username": .s(username),
            "score": .n(String(score))
        ]

        let input = PutItemInput(
            item: item,
            tableName: tableName
        )

        do {
            _ = try await client.putItem(input: input)
        } catch {
            throw error
        }
    }
    
//    func deletePlayer(playerID: String) async throws {
//        guard let client = ddbClient else {
//            throw GnomyScoresError.uninitializedClient
//        }
//        
//        let input = DeleteItemInput(
//            key: [
//                "playerID": .s(playerID)
//            ],
//            tableName: tableName
//        )
//        
//        do {
//            _ = try await client.deleteItem(input: input)
//            print("Successfully deleted the player")
//        } catch {
//            print("failed to delete the player")
//            throw error
//        }
//    }
//    
    func getLeaderboard() async throws -> [PlayerDBInfo] {
        guard let client = ddbClient else {
            throw GnomyScoresError.uninitializedClient
        }

        var players: [PlayerDBInfo] = []

        let scanInput = ScanInput(tableName: tableName)

        do {
            let output = try await client.scan(input: scanInput)
            guard let items = output.items else {
                return Array(repeating: PlayerDBInfo(id: "",username: "Filler", highscore: -1), count: 5)
            }

            for item in items {
                if
                    let playerIDAttr = item["playerID"],
                    case let .s(playerID) = playerIDAttr,
                    let usernameAttr = item["username"],
                    case let .s(username) = usernameAttr,
                    let scoreAttr = item["score"],
                    case let .n(scoreStr) = scoreAttr,
                    let score = Int64(scoreStr)
                {
                    let player = PlayerDBInfo(id: playerID, username: username, highscore: score)
                    players.append(player)
                }
            }

            // Sort descending and pad if necessary
            let sorted = players.sorted { $0.highscore > $1.highscore }
            var topPlayers = Array(sorted.prefix(5))

            while topPlayers.count < 5 {
                topPlayers.append(PlayerDBInfo(id:"", username: "PlayerDNE", highscore: -1))
            }

            return topPlayers

        } catch {
            print("Failed to fetch leaderboard: \(error)")
            throw error
        }
    }



    /// Wait for the table to become active after creation.
    private func waitForTableActive() async throws {
        while try await !tableExists() {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
