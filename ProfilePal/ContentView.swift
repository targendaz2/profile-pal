//
//  ContentView.swift
//  ProfilePal
//
//  Created by David Rosenberg on 9/10/26.
//

import SwiftUI

enum PayloadView {
    case form, plist
}

struct ContentView: View {
    @State private var selectedView: PayloadView = .form
    @State private var isAddSourcePresented: Bool = false

    var body: some View {
        NavigationSplitView {
            List {
                Section("Payloads") {
                    HStack {
                        Label {
                            Text("General")
                        } icon: {
                            Image(systemName: "square")
                        }

                        Spacer()

                        Text("8")
                    }

                    HStack {
                        Label {
                            Text("Jamf Setup Manager")
                        } icon: {
                            Image(systemName: "square")
                        }

                        Spacer()

                        Text("14")
                    }

                    HStack {
                        Label {
                            Text("Microsoft Edge")
                        } icon: {
                            Image(systemName: "square")
                        }

                        Spacer()

                        Text("22")
                    }

                    Button(action: {}) {
                        Label("Add Payload", systemImage: "plus")
                    }
                    .buttonStyle(.link)
                }

                Section("Sources") {
                    Label {
                        Text("ProfileManifests")
                    } icon: {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.green)
                    }

                    Label {
                        Text("Acme Internal")
                    } icon: {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.blue)
                    }

                    Button {
                        isAddSourcePresented = true
                    } label: {
                        Label("Add Source", systemImage: "plus")
                    }
                    .buttonStyle(.link)
                    .sheet(isPresented: $isAddSourcePresented) {
                        AddSourceView()
                    }
                }

                Spacer()
            }
            .navigationSplitViewColumnWidth(196)
        } detail: {
            Text("World")
        }
        .toolbar {
            ToolbarItem {
                Picker("View", selection: $selectedView) {
                    Text("Form").tag(PayloadView.form)
                    Text("Plist").tag(PayloadView.plist)
                }.pickerStyle(.segmented)
            }
        }
    }
}

#Preview {
    ContentView()
}
