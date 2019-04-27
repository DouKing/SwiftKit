//
//  NewCommand.swift
//  Kit
//
//  Created by Sven Tiigi on 27.04.19.
//

import Foundation
import SwiftCLI

// MARK: - NewCommand

/// The NewCommand
class NewCommand {
    
    // MARK: Properties
    
    /// The optional ProjectName Parameter
    let projectNameParameter = OptionalParameter()
    
    /// The ProjectDirectory
    var projectDirectory: ProjectDirectory

    /// The GitConfigService
    let gitConfigService: GitConfigService
    
    /// The TemplateCloneService
    let templateCloneService: TemplateCloneService
    
    /// The TemplatePlaceholderMigrationService
    let templatePlaceholderMigrationService: TemplatePlaceholderMigrationService
    
    /// Designated Initializer
    ///
    /// - Parameters:
    ///   - projectDirectory: The ProjectDirectory. Default value `.init`
    ///   - gitConfigService: The GitConfigService
    ///   - templateCloneService: The TemplateCloneService
    ///   - templatePlaceholderMigrationService: The TemplatePlaceholderMigrationService
    init(projectDirectory: ProjectDirectory = .init(),
         gitConfigService: GitConfigService,
         templateCloneService: TemplateCloneService,
         templatePlaceholderMigrationService: TemplatePlaceholderMigrationService) {
        self.projectDirectory = projectDirectory
        self.gitConfigService = gitConfigService
        self.templateCloneService = templateCloneService
        self.templatePlaceholderMigrationService = templatePlaceholderMigrationService
    }
    
}

// MARK: - Command

extension NewCommand: Command {
    
    /// The name
    var name: String {
        return "new"
    }
    
    /// Executes the command
    ///
    /// - Throws: CLI.Error if command cannot execute successfully
    func execute() throws {
        // Print Bootstrap
        self.printBootstrap()
        // Check if a ProjectName Parameter value is available
        if let projectNameParameterValue = self.projectNameParameter.value {
            // Append value to ProjectDirectory Path
            self.projectDirectory.path += "/\(projectNameParameterValue)"
        }
        // Initialize TemplatePlacerholder
        let templatePlaceholder = TemplatePlaceholder(
            projectName: self.projectNameParameter.value ?? self.askForProjectName(destination: self.projectDirectory.path),
            authorName: self.askForAuthorName(),
            authorEmail: self.askForAuthorEmail(),
            repositoryURL: self.askForRepositoryURL(destination: self.projectDirectory.path),
            organizationName: self.askForOrganizationName(),
            bundleIdentifier: self.askForBundleIdentifier()
        )
        // Print Summary
        self.printSummary(with: templatePlaceholder)
        // Ask for Procceed
        self.askForProceed()
        // Print Start
        self.printStart(with: templatePlaceholder)
        // Clone Template
        try self.templateCloneService.clone(atPath: self.projectDirectory.path)
        /// Migrate Template
        self.templatePlaceholderMigrationService.migrate(
            atPath: self.projectDirectory.path,
            placeholder: templatePlaceholder
        )
        // Print Finish
        self.printFinish(with: templatePlaceholder)
    }
    
}

extension NewCommand {
    
    func printBootstrap() {
        stdout <<< "Kit-Generator 📦\n"
    }
    
    func printSummary(with templatePlaceholder: TemplatePlaceholder) {
        
    }
    
    func printStart(with templatePlaceholder: TemplatePlaceholder) {
        stdout <<< "🚀  Starting to generate \(templatePlaceholder.projectName)..."
    }
    
    func printFinish(with templatePlaceholder: TemplatePlaceholder) {
        stdout <<< "\(templatePlaceholder.projectName) is ready to go 🎉 Good luck with your Kit 🚀"
    }
    
    
}


extension NewCommand {
    
    func printError(_ message: String) {
        stderr <<< message
    }
    
    func askForRequiredInfo(question: String, errorMessage errorMessageClosure: @autoclosure () -> String) -> String {
        print(question)
        
        guard let info = readLine()?.nonEmpty else {
            printError("\(errorMessageClosure()). Try again.")
            return askForRequiredInfo(question: question, errorMessage: errorMessageClosure())
        }
        
        return info
    }
    
    func askForOptionalInfo(question: String, questionSuffix: String = "You may leave this empty.") -> String? {
        print("\(question) \(questionSuffix)")
        return readLine()?.nonEmpty
    }
    
    func askForBooleanInfo(question: String) -> Bool {
        let errorMessage = "Please enter Y/y (yes) or N/n (no)"
        let answerString = askForRequiredInfo(question: "\(question) (Y/N)", errorMessage: errorMessage)
        
        switch answerString.lowercased() {
        case "y":
            return true
        case "n":
            return false
        default:
            printError("\(errorMessage). Try again.")
            return askForBooleanInfo(question: question)
        }
    }
    
}

extension NewCommand {
    
    func askForProjectName(destination: String) -> String {
        let projectFolderName = destination.withoutSuffix("/").components(separatedBy: "/").last!
        
        let projectName = askForOptionalInfo(
            question: "📛  What's the name of your project?",
            questionSuffix: "(Leave empty to use the name of the project folder: \(projectFolderName))"
        )
        
        return projectName ?? projectFolderName
    }
    
    func askForAuthorName() -> String {
        let gitName = self.gitConfigService.getValue(forKey: "user.name")
        let question = "👶  What's your name?"
        
        if let gitName = gitName {
            let authorName = askForOptionalInfo(question: question, questionSuffix: "(Leave empty to use your git config name: \(gitName))")
            return authorName ?? gitName
        }
        
        return askForRequiredInfo(question: question, errorMessage: "Your name cannot be empty")
    }
    
    func askForAuthorEmail() -> String? {
        let gitEmail = self.gitConfigService.getValue(forKey: "user.email")
        let question = "📫  What's your email address (for Podspec)?"
        
        if let gitEmail = gitEmail {
            let authorEmail = askForOptionalInfo(question: question, questionSuffix: "(Leave empty to use your git config email: \(gitEmail))")
            return authorEmail ?? gitEmail
        }
        
        return askForOptionalInfo(question: question)
    }
    
    func askForRepositoryURL(destination: String) -> String? {
        let gitURL = try? capture(bash: "cd \(destination) && git remote get-url origin")
            .stdout
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .withoutSuffix(".git")
        
        let question = "🌍  Any Repository URL that you'll be hosting this project at (for Podspec)?"
        
        if let gitURL = gitURL {
            let gitHubURL = askForOptionalInfo(question: question, questionSuffix: "(Leave empty to use the remote URL of your repo: \(gitURL))")
            return gitHubURL ?? gitURL
        }
        
        return askForOptionalInfo(question: question)
    }
    
    func askForOrganizationName() -> String? {
        return askForOptionalInfo(question: "🏢  What's your organization name?")
    }
    
    func askForBundleIdentifier() -> String? {
        return askForOptionalInfo(question: "🏢  What's your Bundle Identifier?")
    }
    
    func askForProceed() {
        if !askForBooleanInfo(question: "Proceed? ✅") {
            exit(0)
        }
    }
    
    
}


private extension String {
    var nonEmpty: String? {
        guard count > 0 else {
            return nil
        }
        
        return self
    }
    func withoutSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else {
            return self
        }
        
        let startIndex = index(endIndex, offsetBy: -suffix.count)
        return replacingCharacters(in: startIndex..<endIndex, with: "")
    }
}
