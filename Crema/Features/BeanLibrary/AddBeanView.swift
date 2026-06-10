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
    @FocusState private var focused: Field?

    fileprivate enum Field { case name, roaster, origin }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !roaster.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Color.cremaBgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    CremaBackButton { dismiss() }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

                Text("Add Bean")
                    .font(.cremaDisplay(size: 26))
                    .foregroundStyle(Color.cremaTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                CremaDivider()

                // Form
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        formField(label: "bean name *") {
                            CremaFormInput(placeholder: "e.g. Ethiopia Yirgacheffe",
                                          text: $name,
                                          focused: $focused,
                                          field: .name)
                            .submitLabel(.next)
                            .onSubmit { focused = .roaster }
                        }

                        formField(label: "roaster *") {
                            CremaFormInput(placeholder: "e.g. Onyx Coffee Lab",
                                          text: $roaster,
                                          focused: $focused,
                                          field: .roaster)
                            .submitLabel(.next)
                            .onSubmit { focused = .origin }
                        }

                        formField(label: "origin") {
                            CremaFormInput(placeholder: "e.g. Ethiopia, Colombia, Blend…",
                                          text: $origin,
                                          focused: $focused,
                                          field: .origin)
                            .submitLabel(.done)
                            .onSubmit { focused = nil }
                        }

                        formField(label: "process") {
                            CremaSegmentedPicker(
                                options: BeanProcess.allCases,
                                label: { $0.displayName },
                                selection: $process
                            )
                        }

                        formField(label: "roast level") {
                            CremaSegmentedPicker(
                                options: RoastLevel.allCases,
                                label: { $0.displayName },
                                selection: $roastLevel
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .padding(.bottom, 120)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            // Footer CTA — floated above scroll
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 12) {
                    if let err = error {
                        Text(err)
                            .font(.cremaBody(size: 12))
                            .foregroundStyle(Color.cremaError)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    CremaPrimaryButton(
                        label: "Save Bean",
                        isLoading: isLoading,
                        isEnabled: canSave,
                        action: save
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .background(
                    Color.cremaBgPrimary
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -4)
                )
            }
        }
    }

    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.cremaMono(size: 9))
                .tracking(0.08 * 9)
                .foregroundStyle(Color.cremaTextSecondary)
                .textCase(.uppercase)
            content()
        }
    }

    private func save() {
        focused = nil
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

// MARK: - Form input (local, avoids auth FormField coupling)

private struct CremaFormInput: View {
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<AddBeanView.Field?>.Binding
    let field: AddBeanView.Field

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.cremaBody(size: 14))
            .foregroundStyle(Color.cremaTextPrimary)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.sentences)
            .focused(focused, equals: field)
            .tint(Color.cremaCopper)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.cremaInputBg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        focused.wrappedValue == field ? Color.cremaCopper : Color.cremaBorder,
                        lineWidth: 0.5
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: focused.wrappedValue == field)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

#Preview {
    AddBeanView { _ in }
}
