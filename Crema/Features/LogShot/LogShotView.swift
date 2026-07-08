//
//  LogShotView.swift
//  Crema
//

import SwiftUI

// MARK: - Root

struct LogShotView: View {
    let initialBean: Bean?
    let onDismiss: () -> Void

    @State private var step: Step = .form
    @State private var selectedBean: Bean?
    @State private var lastShot: Shot?

    enum Step { case form, confirmed }

    var body: some View {
        switch step {
        case .form:
            NavigationStack {
                LogShotFormView(
                    initialBean: selectedBean ?? initialBean,
                    onLogged: { bean, shot in
                        selectedBean = bean
                        lastShot = shot
                        withAnimation(.easeInOut(duration: 0.25)) { step = .confirmed }
                    }
                )
                .navigationTitle("Log Shot")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onDismiss)
                    }
                }
            }
            .tint(Color.cremaCopper)
        case .confirmed:
            ShotConfirmedView(
                bean: selectedBean ?? initialBean,
                shot: lastShot,
                onDone: onDismiss,
                onLogAnother: {
                    withAnimation(.easeInOut(duration: 0.25)) { step = .form }
                }
            )
        }
    }
}

// MARK: - Form

private struct LogShotFormView: View {
    let initialBean: Bean?
    let onLogged: (Bean?, Shot) -> Void

    @State private var selectedBean: Bean?
    @State private var showBeanPicker = false
    @State private var dose = "18.0"
    @State private var yield = "36.0"
    @State private var time = "28"
    @State private var grinderSetting = ""
    @State private var rating = 7
    @State private var tasteTags: Set<String> = []
    @State private var notes = ""
    @State private var isLoading = false
    @State private var error: String?
    @FocusState private var focused: Field?

    private enum Field { case dose, yield, time, grind, notes }
    private let repo: ShotRepositoryProtocol = ShotRepository()

    private var activeBean: Bean? { selectedBean ?? initialBean }

    private var ratio: String? {
        guard let d = Double(dose), let y = Double(yield), d > 0 else { return nil }
        return String(format: "1:%.2f", y / d)
    }

    private var ratingLabel: String {
        switch rating {
        case 0: return ""
        case 1...2: return "poor"
        case 3...4: return "okay"
        case 5...6: return "good"
        case 7...8: return "great"
        default: return "perfect"
        }
    }

    private var canSave: Bool {
        guard let d = Double(dose), let y = Double(yield), let t = Int(time) else { return false }
        return d > 0 && y > 0 && t > 0
    }

    var body: some View {
        ZStack {
            Color.cremaBgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    beanRow
                    ratioCard
                    measurementRow(
                        ("dose", $dose, "g", .decimalPad, Field.dose, Field.yield),
                        ("yield", $yield, "g", .decimalPad, Field.yield, Field.time)
                    )
                    measurementRow(
                        ("time", $time, "s", .numberPad, Field.time, Field.grind),
                        ("grind", $grinderSetting, "setting", .default, Field.grind, Field.notes)
                    )
                    ratingRow
                    tasteTagRow
                    notesField
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .padding(.bottom, 120)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)

            // Footer
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 12) {
                    if let err = error {
                        Text(err)
                            .font(.cremaBody(size: 14))
                            .foregroundStyle(Color.cremaError)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    CremaPrimaryButton(
                        label: "Save Shot",
                        isLoading: isLoading,
                        isEnabled: canSave,
                        action: save
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .background(
                    Color.cremaBgPrimary
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -4)
                )
            }
        }
        .sheet(isPresented: $showBeanPicker) {
            BeanPickerSheet(selected: $selectedBean)
        }
    }

    // MARK: Sub-views

    private var beanRow: some View {
        Button { showBeanPicker = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("bean")
                        .font(.cremaMono(size: 11))
                        .tracking(0.08 * 11)
                        .foregroundStyle(Color.cremaTextSecondary)
                        .textCase(.uppercase)
                    if let bean = activeBean {
                        Text(bean.name)
                            .font(.cremaBody(size: 17, weight: .medium))
                            .foregroundStyle(Color.cremaTextPrimary)
                        if let roaster = bean.roaster {
                            Text(roaster)
                                .font(.cremaBody(size: 14))
                                .foregroundStyle(Color.cremaTextSecondary)
                        }
                    } else {
                        Text("Select a bean…")
                            .font(.cremaBody(size: 17))
                            .foregroundStyle(Color.cremaCopper)
                    }
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color.cremaTextSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.cremaInputBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cremaBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var ratioCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ratio")
                    .font(.cremaMono(size: 11))
                    .tracking(0.08 * 11)
                    .foregroundStyle(Color.cremaTextSecondary)
                Text(ratio ?? "—")
                    .font(.cremaDisplay(size: 24))
                    .foregroundStyle(Color.cremaCopper)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: ratio)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cremaBgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cremaBorder, lineWidth: 0.5))
    }

    private func measurementRow(
        _ left: (String, Binding<String>, String, UIKeyboardType, Field, Field),
        _ right: (String, Binding<String>, String, UIKeyboardType, Field, Field)
    ) -> some View {
        HStack(spacing: 12) {
            numericField(left.0, text: left.1, unit: left.2, keyboard: left.3, field: left.4, next: left.5)
            numericField(right.0, text: right.1, unit: right.2, keyboard: right.3, field: right.4, next: right.5)
        }
    }

    private func numericField(
        _ label: String,
        text: Binding<String>,
        unit: String,
        keyboard: UIKeyboardType,
        field: Field,
        next: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(label)
                    .font(.cremaMono(size: 11))
                    .tracking(0.08 * 11)
                    .foregroundStyle(Color.cremaTextSecondary)
                    .textCase(.uppercase)
                Text("(\(unit))")
                    .font(.cremaMono(size: 10))
                    .foregroundStyle(Color.cremaTextSecondary.opacity(0.7))
            }
            TextField("—", text: text)
                .font(.cremaBody(size: 16))
                .foregroundStyle(Color.cremaTextPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(keyboard)
                .focused($focused, equals: field)
                .submitLabel(.next)
                .onSubmit { focused = next }
                .tint(Color.cremaCopper)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.cremaInputBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            focused == field ? Color.cremaCopper : Color.cremaBorder,
                            lineWidth: 0.5
                        )
                )
                .animation(.easeInOut(duration: 0.15), value: focused == field)
        }
        .frame(maxWidth: .infinity)
    }

    private var ratingRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("rating")
                .font(.cremaMono(size: 11))
                .tracking(0.08 * 11)
                .foregroundStyle(Color.cremaTextSecondary)
                .textCase(.uppercase)
            HStack(spacing: 12) {
                CremaRatingSlider(value: $rating)
                Text(ratingLabel)
                    .font(.cremaMono(size: 11))
                    .tracking(0.06 * 11)
                    .foregroundStyle(Color.cremaTextSecondary)
                    .animation(.easeInOut(duration: 0.1), value: rating)
            }
        }
    }

    private var tasteTagRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("taste")
                .font(.cremaMono(size: 11))
                .tracking(0.08 * 11)
                .foregroundStyle(Color.cremaTextSecondary)
                .textCase(.uppercase)
            HStack(spacing: 8) {
                ForEach(["sour", "balanced", "bitter"], id: \.self) { tag in
                    Button {
                        if tasteTags.contains(tag) {
                            tasteTags.remove(tag)
                        } else {
                            tasteTags.insert(tag)
                        }
                    } label: {
                        CremaTasteBadge(tag: tag)
                            .opacity(tasteTags.isEmpty || tasteTags.contains(tag) ? 1 : 0.4)
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: tasteTags)
                }
            }
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("tasting notes")
                .font(.cremaMono(size: 11))
                .tracking(0.08 * 11)
                .foregroundStyle(Color.cremaTextSecondary)
                .textCase(.uppercase)
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Describe the shot — acidity, body, finish…")
                        .font(.cremaBody(size: 16))
                        .foregroundStyle(Color.cremaTextSecondary.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $notes)
                    .font(.cremaBody(size: 16))
                    .foregroundStyle(Color.cremaTextPrimary)
                    .focused($focused, equals: .notes)
                    .tint(Color.cremaCopper)
                    .frame(minHeight: 88)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .background(Color.cremaInputBg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(focused == .notes ? Color.cremaCopper : Color.cremaBorder, lineWidth: 0.5)
            )
            .animation(.easeInOut(duration: 0.15), value: focused == .notes)
        }
    }

    // MARK: Save

    private func save() {
        focused = nil
        guard let d = Double(dose), let y = Double(yield), let t = Int(time) else { return }
        isLoading = true
        error = nil
        Task {
            do {
                let payload = CreateShotPayload(
                    beanId: activeBean?.id,
                    doseG: d,
                    yieldG: y,
                    timeSec: t,
                    grinderSetting: grinderSetting.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                    rating: rating,
                    tasteTags: tasteTags.isEmpty ? nil : Array(tasteTags),
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                )
                let shot = try await repo.createShot(payload)
                onLogged(activeBean, shot)
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Bean picker sheet

private struct BeanPickerSheet: View {
    @Binding var selected: Bean?
    @Environment(\.dismiss) private var dismiss
    @State private var beans: [Bean] = []
    @State private var isLoading = false
    private let repo: BeanRepositoryProtocol = BeanRepository()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().tint(Color.cremaCopper)
                } else {
                    List {
                        ForEach(beans) { bean in
                            Button {
                                selected = bean
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(bean.name)
                                            .font(.cremaBody(size: 17, weight: .medium))
                                            .foregroundStyle(Color.cremaTextPrimary)
                                        if let roaster = bean.roaster {
                                            Text(roaster)
                                                .font(.cremaBody(size: 14))
                                                .foregroundStyle(Color.cremaTextSecondary)
                                        }
                                    }
                                    Spacer()
                                    if selected?.id == bean.id {
                                        Image(systemName: "checkmark")
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.cremaCopper)
                                    }
                                }
                            }
                            .listRowBackground(Color.cremaBgPrimary)
                            .listRowSeparatorTint(Color.cremaBorder)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.cremaBgPrimary.ignoresSafeArea())
                }
            }
            .navigationTitle("Select Bean")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Color.cremaCopper)
        .task {
            isLoading = true
            beans = (try? await repo.fetchBeans()) ?? []
            isLoading = false
        }
    }
}

// MARK: - Confirmed screen

private struct ShotConfirmedView: View {
    let bean: Bean?
    let shot: Shot?
    let onDone: () -> Void
    let onLogAnother: () -> Void

    private var ratio: String {
        guard let s = shot else { return "—" }
        return String(format: "1:%.2f", s.yieldG / s.doseG)
    }

    var body: some View {
        ZStack {
            Color.cremaBgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.cremaBgSurface)
                        .frame(width: 64, height: 64)
                        .overlay(Circle().stroke(Color.cremaBorder, lineWidth: 0.5))
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(Color.cremaCopper)
                }
                .padding(.bottom, 20)

                Text("Shot logged")
                    .font(.cremaDisplay(size: 34))
                    .foregroundStyle(Color.cremaTextPrimary)
                    .padding(.bottom, 6)

                if let bean {
                    Text(bean.name)
                        .font(.cremaBody(size: 15))
                        .foregroundStyle(Color.cremaTextSecondary)
                }

                if let tags = shot?.tasteTags, !tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { CremaTasteBadge(tag: $0) }
                    }
                    .padding(.top, 10)
                }

                Spacer()

                if let shot {
                    VStack(spacing: 0) {
                        let items: [(String, String, String)] = [
                            ("dose",  String(format: "%.1f", shot.doseG),  "g"),
                            ("yield", String(format: "%.1f", shot.yieldG), "g"),
                            ("time",  "\(shot.timeSec)",                   "s"),
                            ("ratio", ratio,                               ""),
                            ("grind", shot.grinderSetting ?? "—",          ""),
                        ]
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(items, id: \.0) { label, value, unit in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(label)
                                        .font(.cremaMono(size: 11))
                                        .tracking(0.08 * 11)
                                        .foregroundStyle(Color.cremaTextSecondary)
                                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                                        Text(value)
                                            .font(.cremaDisplay(size: 22))
                                            .foregroundStyle(Color.cremaTextPrimary)
                                        if !unit.isEmpty {
                                            Text(unit)
                                                .font(.cremaBody(size: 13))
                                                .foregroundStyle(Color.cremaTextSecondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("rating")
                                    .font(.cremaMono(size: 11))
                                    .tracking(0.08 * 11)
                                    .foregroundStyle(Color.cremaTextSecondary)
                                CremaRatingBadge(value: shot.rating)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)
                    }
                    .background(Color.cremaBgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cremaBorder, lineWidth: 0.5))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }

                VStack(spacing: 0) {
                    CremaPrimaryButton(label: "Done", action: onDone)
                        .padding(.horizontal, 20)

                    Button("log another", action: onLogAnother)
                        .font(.cremaBody(size: 15))
                        .foregroundStyle(Color.cremaTextSecondary)
                        .padding(.top, 16)
                        .padding(.bottom, 36)
                }
            }
        }
    }
}

// MARK: - Helpers

private extension String {
    var nilIfEmpty: String? { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self }
}

#Preview {
    LogShotView(initialBean: nil) { }
}
