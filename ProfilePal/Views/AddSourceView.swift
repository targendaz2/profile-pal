//
//  AddSourceView.swift
//  ProfilePal
//
//  Created by David Rosenberg on 9/13/26.
//

import SwiftUI

struct AddSourceView: View {
    @State private var selectedViewMode: ViewMode = .git
    @State private var sourceDisplayName: String = ""
    @State private var sourceRepo: String = ""
    @State private var sourceBranch: String = ""
    @State private var sourceSubpath: String = ""
    @State private var sourceAuth: AuthType = .none

    enum ViewMode {
        case git, local
    }

    enum AuthType {
        case none, token
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Connect a manifest repository or local folder.")
            Form {
                Picker("Source", selection: $selectedViewMode) {
                    Text("Git repository").tag(ViewMode.git)
                    Text("Local folder").tag(ViewMode.local)
                }.pickerStyle(.segmented)

                TextField(text: $sourceDisplayName, prompt: Text("ProfileManifests")) {
                    Text("Display name")
                }

                HStack {
                    TextField(
                        text: $sourceRepo, prompt: Text("git@github.com:acme/mac-manifests.git"),
                    ) {
                        Text("Repository URL")
                    }

                    Button("Test") {}
                }

                TextField(text: $sourceBranch, prompt: Text("main")) {
                    Text("Branch")
                }

                TextField(text: $sourceSubpath, prompt: Text("manifests/")) {
                    Text("Subpath")
                }

                Picker("Authentication", selection: $sourceAuth) {
                    Text("Public").tag(AuthType.none)
                    Text("Access Token").tag(AuthType.token)
                }.pickerStyle(.segmented)
            }

            HStack {
                Button("Cancel") {}
                Button("Add Source") {}
            }
        }
        .navigationTitle("Add Source")
        .padding()
    }
}

#Preview {
    Color(.systemFill)
        .ignoresSafeArea()
        .overlay(
            AddSourceView()
                .frame(width: 500, height: 300) 
                .background(Color(.windowBackgroundColor))
                .cornerRadius(12)
                .shadow(radius: 10)
        )

}
