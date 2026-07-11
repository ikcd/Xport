import XCTest
@testable import Xport

// MARK: - DatabaseReader Tests

final class DatabaseReaderTests: XCTestCase {

    private var tempDir: URL!
    private let reader = DatabaseReader()

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testFindDatabaseFilesEmpty() {
        let results = reader.findDatabaseFiles(inFolder: tempDir.path)
        XCTAssertEqual(results, [])
    }

    func testFindDatabaseFilesFindsDBFiles() throws {
        let dbFile = tempDir.appendingPathComponent("test.db")
        FileManager.default.createFile(atPath: dbFile.path, contents: nil)
        let results = reader.findDatabaseFiles(inFolder: tempDir.path)
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].hasSuffix("test.db"))
    }

    func testFindDatabaseFilesIgnoresNonDB() throws {
        FileManager.default.createFile(atPath: tempDir.appendingPathComponent("notes.txt").path, contents: nil)
        FileManager.default.createFile(atPath: tempDir.appendingPathComponent("archive.zip").path, contents: nil)
        let results = reader.findDatabaseFiles(inFolder: tempDir.path)
        XCTAssertEqual(results, [])
    }

    func testFindDatabaseFilesMultipleDBs() throws {
        for name in ["a.db", "b.db", "c.db"] {
            FileManager.default.createFile(atPath: tempDir.appendingPathComponent(name).path, contents: nil)
        }
        let results = reader.findDatabaseFiles(inFolder: tempDir.path)
        XCTAssertEqual(results.count, 3)
    }

    func testFindDatabaseFilesInvalidFolder() {
        let results = reader.findDatabaseFiles(inFolder: "/nonexistent/path/that/does/not/exist")
        XCTAssertEqual(results, [])
    }

    func testReadConversationsMetadataInvalidFile() {
        let results = reader.readConversationsMetadata(fromFile: "/nonexistent/path.db")
        XCTAssertEqual(results, [])
    }

    func testReadConversationsMetadataEmptyFile() throws {
        // An empty file is not a valid SQLite database, so result should be empty
        let emptyFile = tempDir.appendingPathComponent("empty.db")
        FileManager.default.createFile(atPath: emptyFile.path, contents: Data())
        let results = reader.readConversationsMetadata(fromFile: emptyFile.path)
        XCTAssertEqual(results, [])
    }
}
