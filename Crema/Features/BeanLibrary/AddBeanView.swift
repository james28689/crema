//
//  AddBeanView.swift
//  Crema
//

import SwiftUI

struct AddBeanView: View {
    let onSave: (CreateBeanPayload) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var roaster = ""
    @State private var origin = ""
    @State private var process: BeanProcess = .washed
    @State private var roastLevel: RoastLevel = .medium
    @State private var isLoading = false
    @State private var error: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !roaster.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Roaster", text: $roaster)
                    TextField("Origin", text: $origin)
                }
                .listRowBackground(Color.cremaBgSurface)

                Section {
                    Picker("Process", selection: $process) {
                        ForEach(BeanProcess.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    Picker("Roast Level", selection: $roastLevel) {
                        ForEach(RoastLevel.allCases, id: \.self) { l in
                            Text(l.displayName).tag(l)
                        }
                    }
                }
                .listRowBackground(Color.cremaBgSurface)

                if let err = error {
                    Section {
                        Text(err)
                            .font(.cremaBody(size: 14))
                            .foregroundStyle(Color.cremaError)
                    }
                    .listRowBackground(Color.cremaBgSurface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.cremaBgPrimary.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Bean")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                            .bold()
                            .disabled(!canSave)
                    }
                }
            }
        }
        .tint(Color.cremaCopper)
    }

    private func save() {
        guard canSave else { return }
        isLoading = true
        error = nil
        Task {
            do {
                let payload = CreateBeanPayload(
                    name: name.trimmingCharacters(in: .whitespaces),
                    roaster: roaster.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                    origin: origin.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                    process: process,
                    roastLevel: roastLevel,
                    roastDate: nil,
                    isActive: true
                )
                try await onSave(payload)
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

#Preview {
    AddBeanView { _ in }
}
